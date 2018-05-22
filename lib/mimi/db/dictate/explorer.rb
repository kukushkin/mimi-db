# frozen_string_literal: true

module Mimi
  module DB
    module Dictate
      module Explorer
        #
        # Discovers a schema of an existing DB table.
        #
        # Returns nil if the DB table does not exist.
        #
        # @param table_name [String,Symbol]
        # @return [Mimi::DB::Dictate::SchemaDefinition,nil]
        #
        def self.discover_schema(table_name)
          table_name = table_name.to_sym
          return nil unless connection.tables.include?(table_name)
          sd = Mimi::DB::Dictate::SchemaDefinition.new(table_name)
          discover_schema_columns(sd)
          discover_schema_indexes(sd)
          sd
        end

        # Discovers columns of an existing DB table and registers them in schema definition
        #
        # @private
        # @param schema_definition [Mimi::DB::Dictate::SchemaDefinition]
        #
        def self.discover_schema_columns(schema_definition)
          columns = connection.schema(schema_definition.table_name).to_h
          columns.each do |name, c|
            params = {
              as: c[:type],
              type: c[:type],
              size: c[:max_length],
              primary_key: c[:primary_key],
              auto_increment: c[:auto_increment], # FIXME: SQLite does not report autoincremented fields
              null: c[:allow_null],
              not_null: !c[:allow_null],
              db_default: c[:default],
              default: c[:default],
              db_type: c[:db_type]
            }
            schema_definition.field(name, params)
          end
        end
        private_class_method :discover_schema_columns

        # Discovers indexes of an existing DB table and registers them in schema definition
        #
        # @private
        # @param schema_definition [Mimi::DB::Dictate::SchemaDefinition]
        #
        def self.discover_schema_indexes(schema_definition)
          indexes = connection.indexes(schema_definition.table_name).to_h
          pk = discover_primary_key(schema_definition.table_name)
          indexes.each do |idx_name, idx_data|
            params = {
              name: idx_name,
              primary_key:  idx_data[:columns] == pk,
              unique: idx_data[:unique]
            }
            schema_definition.index(idx_data[:columns], params)
          end
        end
        private_class_method :discover_schema_indexes

        # Discovers primary key of an existing DB table
        #
        # @private
        # @param table_name [String,Symbol]
        #
        # @return [Array<Symbol>]
        #
        def self.discover_primary_key(table_name)
          s = connection.schema(table_name).to_h
          s.keys.select { |name| s[name][:primary_key] }
        end

        # Returns ActiveRecord DB connection
        #
        def self.connection
          Mimi::DB.connection
        end
      end # module Explorer
    end # module Dictate
  end # module DB
end # module Mimi
