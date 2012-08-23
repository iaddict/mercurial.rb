module Mercurial
  module Style
    extend self
    
    FIELD_SEPARATOR = "|/|>&&<|/|"
    CHANGESET_SEPARATOR = "|//|&&&|//|\n"
    
    def root_path
      File.expand_path('../../styles', __FILE__)
    end
    
    def changeset
      File.join(root_path, 'changeset.style')
    end
    
    def parse_changesets(repo, text)
      text.split(CHANGESET_SEPARATOR).map do |changeset|
        values = changeset.split(FIELD_SEPARATOR)

        changeset = {
          :node => values[0],
          :author => values[1],
          :email => values[2],
          :date => values[3],
          :message => values[4],
          :files_modified => values[5],
          :files_added => values[6],
          :files_deleted => values[7],
          :files_copied => values[8],
          :branch => values[9],
          :tags => values[10],
          :parents => values[11]
        }

        Mercurial::Commit.new repo, changeset
      end
    end
  end
end
