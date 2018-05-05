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
        # @param table_name [String]
        # @return [Mimi::DB::Dictate::SchemaDefinition,nil]
        #
        def self.discover_schema(table_name)
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
          columns = connection.columns(schema_definition.table_name)
          pk = connection.primary_key(schema_definition.table_name)
          columns.each do |c|
            params = {
              as: c.type,
              limit: c.limit,
              primary_key: (pk == c.name),
              auto_increment: false, # FIXME: SQLite does not report autoincremented fields
              not_null: !c.null,
              default: c.default,
              sql_type: c.sql_type
            }
            schema_definition.field(c.name, params)
          end
        end
        private_class_method :discover_schema_columns

        # Discovers indexes of an existing DB table and registers them in schema definition
        #
        # @private
        # @param schema_definition [Mimi::DB::Dictate::SchemaDefinition]
        #
        def self.discover_schema_indexes(schema_definition)
          indexes = connection.indexes(schema_definition.table_name)
          pk = connection.primary_key(schema_definition.table_name)
          indexes.each do |idx|
            params = {
              name: idx.name,
              primary_key:  idx.columns == [pk],
              unique: idx.unique
            }
            schema_definition.index(idx.columns, params)
          end
        end
        private_class_method :discover_schema_indexes

        # Returns ActiveRecord DB connection
        #
        def self.connection
          ActiveRecord::Base.connection
        end
      end # module Explorer
    end # module Dictate
  end # module DB
end # module Mimi
