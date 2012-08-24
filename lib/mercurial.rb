require 'mercurial/version'
require 'mercurial/configuration'
require 'mercurial/ffi'
require 'mercurial/style'
require 'mercurial/changed_file'
require 'mercurial/file'
require 'mercurial/directory'
require 'mercurial/branch'
require 'mercurial/commit'
require 'mercurial/blame'
require 'mercurial/blame_line'
require 'mercurial/repository'

module Mercurial
  class << self
    attr_reader :configuration
    # Access instance of Mercurial::Configuration.
    #
    #  config = Mercurial.configuration
    #  config.logger # => <Logger ...>
    #
    def configuration
      @configuration ||= Mercurial::Configuration.new
    end
    
    # Change global settings.
    #
    #  Mercurial.configure do |conf|
    #    conf.logger = Rails.logger
    #  end
    #
    def configure      
      yield(configuration)
    end
  end
end
