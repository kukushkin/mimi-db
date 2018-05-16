module Mimi
  module DB
    module Extensions
      def self.start
        require_relative 'extensions/sequel-postgres'
        require_relative 'extensions/sequel-cockroachdb'
      end
    end # module Extensions
  end # module DB
end # module Mimi
