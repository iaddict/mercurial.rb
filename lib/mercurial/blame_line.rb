module Mercurial
  class BlameLine
    attr_reader :repository
    attr_reader :author
    attr_reader :revision
    attr_reader :line
    attr_reader :text
    
    def initialize(repository, opts)
      @repository = repository
      @author = opts[:author]
      @revision = opts[:revision]
      @line = opts[:line]
      @text = opts[:text]
    end
  end
end
