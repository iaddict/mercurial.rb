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
    #  :files_modified=>"M images/portfolio/CRS.jpg;M index.html;",
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
      @branch = opts[:branch]
    end
  end
end
