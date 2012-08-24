module Mercurial
  class Blame
    BLAME_RE = /^(.+) (\w{12}): *(\d+): (.*)$/
    
    attr_reader :repository
    attr_reader :data
    
    def initialize(repository, data)
      @repository = repository
      @data = data
    end
    
    def lines
      data.lines.map do |line|
        match = line.match(BLAME_RE)
        BlameLine.new(self.repository, {author: match[1], revision: match[2], line: match[3], text: match[4]})
      end
    end
  end
end
