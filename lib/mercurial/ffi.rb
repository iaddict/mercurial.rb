require 'rubypython'

module Mercurial
  module FFI
    extend self
    
    def start
      mercurial_path = ::File.expand_path('../../../vendor/mercurial/', __FILE__)
      hg_run_path = ::File.expand_path('../../python_exts/', __FILE__)
      
      RubyPython.start
      RubyPython.import('pkg_resources') rescue nil
      sys = RubyPython.import('sys')
      sys.path.insert(0, mercurial_path)
      sys.path.insert(0, hg_run_path)

      @mercurial = RubyPython.import('mercurial')
      @hg_run = RubyPython.import('hg_run')
    end
    
    def stop
      RubyPython.stop
      @mercurial = nil
      @hg_run = nil
    end
    
    def run_command(args)
      start unless hg_run
      args = args.reject &:empty?
      debug("hg #{args.join(' ')}")
      success, output = hg_run.run(args).rubify
      error("  => #{output}") unless success
      success, output
    end
    
    private
    
    attr_reader :mercurial, :hg_run
    
    def error(msg)
      Mercurial.configuration.logger.error(msg)
    end

    def debug(msg)
      Mercurial.configuration.logger.debug(msg)
    end
  end
end
