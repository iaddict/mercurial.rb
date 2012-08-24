module Mercurial
  class Branch
    attr_reader :repository
    attr_reader :name
    attr_reader :status
    attr_reader :commit_node

    def initialize(repository, opts = {})
      @repository = repository
      @name = opts[:name]
      @status = opts[:status]
      @branch = opts[:commit_node]
    end
    
    def active?
      status == 'active'
    end
    
    def closed?
      status == 'closed'
    end
    
    def inactive?
      status == 'inactive'
    end
  end
end
