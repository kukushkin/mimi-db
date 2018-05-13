module Mimi
  module DB
    class Model
      extend Sequel::Inflections

      # Returns the corresponding table name
      #
      # @return [String]
      #
      def self.table_name
        pluralize(underscore(demodulize(name))).to_sym
      end
    end # class Model
  end # module DB
end # module Mimi
