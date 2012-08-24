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
    
    def commit(revision)
      options = {
        '--style' => Mercurial::Style.changeset,
        '--rev' => revision
      }
      
      success, output = run_command('log', options)
      return nil unless success

      Mercurial::Style.parse_changesets(self, output).first
    end
    
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
      full_path = ::File.expand_path(path, self.path)
      options = {
        '--style' => Mercurial::Style.changeset,
        '--rev' => "ancestor(max(file('#{full_path}')), #{revision})"
      }
      
      success, output = run_command('log', options)
      return nil unless success

      Mercurial::Style.parse_changesets(self, output).first
    end
    
    def branches
      success, output = run_command('branches', ['-c', '--debug'])
      return [] unless success
      
      output.lines.map do |line|
        match = line.match(/([\w-]+)\s+\d+:(\w+)\s*\(*(\w*)\)*/)
        name = match[1]
        last_commit = match[2]
        status = match[3].empty? ? 'active' : match[3]
        Mercurial::Branch.new(self, {name: name, status: status, commit_node: last_commit})
      end
    end
    
    def run_command(command, options = {})
      args = [command]
      args += options.flatten
      args += ['--repository', path]

      Mercurial::FFI.run_command(args)
    end
  end
end
