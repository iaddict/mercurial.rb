require 'json'
require 'base64'
require 'timeout'
require 'posix/spawn'

# Error class
class MercurialError < IOError
end

module Mercurial
  module Popen
    include POSIX::Spawn
    extend self
    
    # Get things started by opening a pipe to hg_run, a Python process that
    # talks to the Mercurial library. We'll talk back and forth across this pipe.
    def start
      mercurial_path = ::File.expand_path('../../../vendor/mercurial/', __FILE__)
      hg_run_path = ::File.expand_path('../../python_exts/hg_run.py', __FILE__)
      
      ENV['MERCURIAL_PATH'] = mercurial_path
      
      # Make sure we kill off the child when we're done
      at_exit { stop "Exiting" }
      
      # A pipe to the hg_run python process. #popen4 gives us
      # the pid and three IO objects to write and read.
      @pid, @in, @out, @err = popen4(hg_run_path)
      info "Starting pid #{@pid.to_s} with fd #{@out.to_i.to_s}."
    end
    
    # Stop the child process by issuing a kill -9.
    #
    # We then call waitpid() with the pid, which waits for that particular
    # child and reaps it.
    #
    # kill() can set errno to ESRCH if, for some reason, the file
    # is gone; regardless the final outcome of this method
    # will be to set our @pid variable to nil.
    #
    # Technically, kill() can also fail with EPERM or EINVAL (wherein
    # the signal isn't sent); but we have permissions, and
    # we're not doing anything invalid here.
    def stop(reason)
      if @pid
        begin
          Process.kill('KILL', @pid)
          Process.waitpid(@pid)
        rescue Errno::ESRCH, Errno::ECHILD
        end
      end
      info "Killing pid: #{@pid.to_s}. Reason: #{reason}"
      @pid = nil
    end
    
    # Check for a @pid variable, and then hit `kill -0` with the pid to
    # check if the pid is still in the process table. If this function
    # gives us an ENOENT or ESRCH, we can also safely return false (no process
    # to worry about).
    #
    # Returns true if the child is alive.
    def alive?
      return true if @pid && Process.kill(0, @pid)
      false
    rescue Errno::ENOENT, Errno::ESRCH
      false
    end
    
    def run_command(args)
      args = args.reject(&:empty?)
      ret_values = hg_run(args)
      fout = Base64.decode64(ret_values['fout']).force_encoding('UTF-8')
      ferr = Base64.decode64(ret_values['ferr']).force_encoding('UTF-8')
      
      if ferr.empty?
        [true, fout]
      else
        error(ferr)
        [false, ferr]
      end
    end
    
    private
    
    attr_reader :mercurial, :hg_run
    
    # If this happens that be too slow, we shouldn't serialize everything - 
    # Just serialize the header and dump the raw data.
    def hg_run(args)
      # Open the pipe if necessary
      start unless alive?
      
      begin
        # Timeout requests that take too long.
        timeout_time = 3

        Timeout::timeout(timeout_time) do
          out_header = JSON.dump(args: args)

          # Get the size of the header itself and write that.
          bits = get_fixed_bits_from_header(out_header)
          @in.write(bits)

          # hg_run is now waiting for the header.
          write_data(out_header)

          # hg_run will now return data to us. First it sends the header.
          header = get_header

          # Now handle the header, any read any more data required.
          res = handle_header_and_return(header)

          # Finally, return what we got.
          return_result(res)
        end
      rescue Timeout::Error => boom
        error "Timeout on a hg_run call"
        stop "Timeout on hg_run call."
      end

    rescue Errno::EPIPE, EOFError
    stop "EPIPE"
    raise MercurialError, "EPIPE"
    end
    
    def get_fixed_bits_from_header(out_header)
      size = out_header.bytesize

      # Fixed 32 bits to represent the int. We return a string
      # represenation: e.g, "00000000000000000000000000011110"
      Array.new(32) { |i| size[i] }.reverse!.join
    end
    
    # Write data to hg_run, the Python Process.
    #
    # Returns nothing.
    def write_data(out_header)
      @in.write(out_header)
      debug "Out header: #{out_header.to_s}"
    end
    
    # Read the header via the pipe.
    #
    # Returns a header.
    def get_header
      begin
        size = @out.read(33)
        size = size[0..-2]

        # Sanity check the size
        unless size_check(size)
          error "Size returned from hg_run invalid."
          stop "Size returned from hg_run invalid."
          raise MercurialError, "Size returned from hg_run invalid."
        end

        # Read the amount of bytes we should be expecting. We first
        # convert the string of bits into an integer.
        header_bytes = size.to_s.to_i(2) + 1
        info "Size in: #{size.to_s} (#{header_bytes.to_s})"
        @out.read(header_bytes)
      rescue
        error "Failed to get header."
        stop "Failed to get header."
        raise MercurialError, "Failed to get header."
      end
    end
    
    # Based on the header we receive, determine if we need
    # to read more bytes, and read those bytes if necessary.
    def handle_header_and_return(header)
      unless header
        error "No header data back."
        stop "No header data back."
        raise MercurialError, "No header received back."
      end

      header = header_to_json(header)
      bytes = header["bytes"]

      # Read more bytes (the actual response body)
      @out.read(bytes.to_i)
    end
    
    # Sanity check for size (32-arity of 0's and 1's)
    def size_check(size)
      size_regex = /[0-1]{32}/
      if size_regex.match(size)
        true
      else
        false
      end
    end
    
    # Convert a text header into JSON for easy access.
    def header_to_json(header)
      info "In header:" + header.to_s
      header = JSON.parse(header)

      if header["error"]
        # Raise this as a Ruby exception of the MercurialError class.
        # Stop so we don't leave the pipe in an inconsistent state.
        error "Failed to convert header to JSON."
        stop header["error"]
        raise MercurialError, header["error"]
      else
        header
      end
    end

    # Return the final result for the API.
    def return_result(res)
      JSON.parse(res)
    end

    def info(msg)
      Mercurial.configuration.logger.info(msg)
    end

    def error(msg)
      Mercurial.configuration.logger.error(msg)
    end

    def debug(msg)
      Mercurial.configuration.logger.debug(msg)
    end
  end
end
