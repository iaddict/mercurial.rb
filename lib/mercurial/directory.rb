module Mercurial
  class Directory
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
    
    def name
      ::File.basename(path)
    end
    
    def directory?
      true
    end
    
    def file?
      false
    end
  end
end
