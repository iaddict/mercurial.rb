module Mercurial
  class Repository
    attr_reader :path
    
    def initialize(path)
      @path = path
    end
    
    def tip
      options = {
        '--style' => Mercurial::Style.changeset
      }
      
      success, output = run_command('tip', options)
      return nil unless success

      Mercurial::Style.parse_changesets(self, output).first
    end
    alias head tip
    
    def parents(revision = 'tip')
      options = {
        '--style' => Mercurial::Style.changeset,
        '--rev' => revision
      }
      
      success, output = run_command('parents', options)
      return nil unless success

      Mercurial::Style.parse_changesets(self, output)
    end
    
    def latest_revision_for_path(path, revision = 'tip')
      full_path = File.expand_path(path, self.path)
      options = {
        '--style' => Mercurial::Style.changeset,
        '--rev' => "ancestor(max(file('#{full_path}')), #{revision})"
      }
      
      success, output = run_command('log', options)
      return nil unless success

      Mercurial::Style.parse_changesets(self, output).first
    end
    
    private
    
    def run_command(command, options = {})
      args = [command]
      args += options.flatten
      args += ['--repository', path]

      Mercurial::FFI.run_command(args)
    end
  end
end
