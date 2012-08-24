module Mercurial
  class File
    attr_reader :repository
    attr_reader :revision
    attr_reader :file_node
    attr_reader :path
    
    def initialize(repository, opts = {})
      @repository = repository
      @revision = opts[:revision]
      @file_node = opts[:file_node]
      @path = opts[:path]
    end

    def content
      success, output = self.repository.run_command('cat', {'--rev' => revision})
      return nil unless success
      output
    end
    
    def name
      ::File.basename(path)
    end

    def directory?
      false
    end
    
    def file?
      true
    end
  end
end
