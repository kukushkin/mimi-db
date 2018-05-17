module Mimi
  module DB
    module Extensions
      def self.start
        adapter_name = Mimi::DB.sequel_config[:adapter]
        require_relative 'extensions/sequel-database'
        case adapter_name
        when 'sqlite'
          require_relative 'extensions/sequel-sqlite'
        when 'postgres'
          require_relative 'extensions/sequel-postgres'
        when 'cockroachdb'
          require_relative 'extensions/sequel-postgres'
          require_relative 'extensions/sequel-cockroachdb'
        else
          # load nothing
        end
        Sequel::Model.plugin :timestamps
      end
    end # module Extensions
  end # module DB
end # module Mimi
