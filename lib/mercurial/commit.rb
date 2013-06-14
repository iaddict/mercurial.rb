require 'date'

module Mercurial
  class Commit
    attr_reader :repository
    attr_reader :node
    attr_reader :author
    attr_reader :date
    attr_reader :message
    attr_reader :branch

    # {:node=>"55e892daee00ee7d887529430b36f4c3fd7eee52",
    #  :author=>"Stefan Huber",
    #  :email=>"MSNexploder@gmail.com",
    #  :date=>"2012-08-17T20:12:57+02:00",
    #  :message=>"testmerge",
    #  :files_modified=>"M images/portfolio/CRS.jpg;\nM index.html;\n",
    #  :files_added=>"",
    #  :files_deleted=>"",
    #  :files_copied=>"",
    #  :branch=>"default",
    #  :tags=>"tip",
    #  :parents=>"51:9032b266be28 50:ebe3036cd3a3 "}
    def initialize(repository, opts = {})
      @repository = repository
      @node = opts[:node]
      @author = opts[:author]
      @date = DateTime.parse(opts[:date])
      @message = opts[:message]
      @files_modified = opts[:files_modified].lines.map { |l| matched = l.match(/M (.*);/); Mercurial::ChangedFile.new(matched[1], 'M') }
      @files_added = opts[:files_added].lines.map { |l| matched = l.match(/A (.*);/); Mercurial::ChangedFile.new(matched[1], 'A') }
      @files_deleted = opts[:files_deleted].lines.map { |l| matched = l.match(/D (.*);/); Mercurial::ChangedFile.new(matched[1], 'D') }
      @branch = opts[:branch]
    end
    
    def changed_files
      @files_modified + @files_added + @files_deleted
    end
    
    def blame(path = '')
      success, output = repository.run_command('blame', {'--rev' => node, '-ucl' => '', path => ''})
      return nil unless success
      
      Mercurial::Blame.new(self.repository, output)
    end
    
    def tree(path = '')
      success, output = repository.run_command('manifest', {'--rev' => node, '--debug' => ''})
      return [] unless success
      
      path = '' if path == '/'
      if path == ''
        search_path = '.*'
      else
        if path.end_with? '/'
          search_path = "#{Regexp.escape(path)}.*"
        else
          search_path = "#{Regexp.escape(path)}$"
        end
      end

      entries = []
      manifest_entries = output.scan(/^(\w{40}) (\d{3}) (\*?) +(#{search_path})/)
      manifest_entries.each do |entry|
        node_id = entry[0]
        fmode = entry[1]
        
        if entry[3] == path
          file_path = entry[3]
        else
          file_path = entry[3][path.length..-1].match(/([^\/]+\/?)/)[1]
        end
        
        entries << {
          node_id: node_id,
          fmode: fmode,
          path: file_path
        }
      end
      
      entries.uniq{ |e| e[:path] }.map do |entry|
        opts = {
          revision: self.node,
          file_node: entry[:node_id],
          path: path == '' || entry[:path] == path ? entry[:path] : ::File.join(path, entry[:path])
        }
        
        if entry[:path].end_with? '/'
          Mercurial::Directory.new self.repository, opts
        else
          Mercurial::File.new self.repository, opts 
        end
      end
    end
  end
end
