module Mercurial
  class ChangedFile
    attr_accessor :name
    attr_reader :mode
    
    def initialize(name, mode)
      @name = name
      @mode = mode
    end
  end
end
