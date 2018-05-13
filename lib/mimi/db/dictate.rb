require_relative 'dictate/dsl'
require_relative 'dictate/schema_definition'
require_relative 'dictate/schema_diff'
require_relative 'dictate/explorer'
require_relative 'dictate/migrator'

module Mimi
  module DB
    module Dictate
      TYPE_DEFAULTS = {
        # sqlite3: {
        #   string: { name: 'varchar', limit: 32 }
        # }
      }.freeze

      def self.included(base)
        base.extend Mimi::DB::Dictate::DSL
      end

      def self.start
        # ActiveRecord::Base.extend Mimi::DB::Dictate::DSL
      end

      def self.schema_definitions
        @schema_definitions ||= {}
      end

      def self.adapter_type
        Mimi::DB.connection.adapter_scheme
        # ca = ActiveRecord::ConnectionAdapters
        # c  = ActiveRecord::Base.connection

        # # TODO: postgres???
        # return :cockroachdb if ca.const_defined?(:CockroachDBAdapter) && c.is_a?(ca::PostgreSQLAdapter)

        # return :postgresql if ca.const_defined?(:PostgreSQLAdapter) && c.is_a?(ca::PostgreSQLAdapter)

        # return :mysql if ca.const_defined?(:AbstractMysqlAdapter) && c.is_a?(ca::AbstractMysqlAdapter)

        # return :sqlite3 if ca.const_defined?(:SQLite3Adapter) && c.is_a?(ca::SQLite3Adapter)

        # raise 'Unrecognized database adapter type'
      end

      # Returns type defaults based on given type:
      #   :string
      #   :text
      #   :integer etc
      #
      def self.type_defaults(type)
        type = type.to_sym
        connection_defaults = {} # ActiveRecord::Base.connection.native_database_types
        adapter_defaults = TYPE_DEFAULTS[DB::Dictate.adapter_type]
        d = (adapter_defaults && adapter_defaults[type]) || connection_defaults[type] || {}
        d = {
          sql_type: d.is_a?(String) ? d : d[:name],
          limit: d.is_a?(String) ? nil : d[:limit]
        }
        if type == :primary_key
          d[:primary_key] = true
          d[:not_null] = true
        end
        d
      end

      # Updates the DB schema to the target schema defined in models
      #
      # Default options from Migrator::DEFAULTS:
      #     destructive: {
      #       tables: false,
      #       columns: false,
      #       indexes: false
      #     },
      #     dry_run: false,
      #     logger: nil # will use ActiveRecord::Base.logger
      #
      # @param opts [Hash]
      #
      def self.update_schema!(opts = {})
        logger = opts[:logger] || ActiveRecord::Base.logger
        logger.info "Mimi::DB::Dictate started updating DB schema"
        t_start = Time.now
        Mimi::DB.all_table_names.each { |t| Mimi::DB::Dictate::Migrator.new(t, opts).run! }
        logger.info 'Mimi::DB::Dictate finished updating DB schema (%.3fs)' % [Time.now - t_start]
      rescue StandardError => e
        logger.error "DB::Dictate failed to update DB schema: #{e}"
        raise
      end

      # Diff existing DB schema and the target schema
      #
      # @param opts [Hash]
      # @return [Hash]
      #
      def self.diff_schema(opts = {})
        logger = opts[:logger] || ActiveRecord::Base.logger
        diff = { add_tables: [], change_tables: [], drop_tables: []}
        Mimi::DB.all_table_names.each do |t|
          m = Mimi::DB::Dictate::Migrator.new(t, opts)
          if m.from_schema && m.to_schema.nil?
            diff[:drop_tables] << t
          elsif m.from_schema && m.to_schema
            t_diff = Mimi::DB::Dictate::SchemaDiff.diff(m.from_schema, m.to_schema)
            diff[:change_tables] << t_diff unless t_diff[:columns].empty? && t_diff[:indexes].empty?
          elsif m.from_schema.nil? &&  m.to_schema
            diff[:add_tables] << m.to_schema
          end
        end
        diff
      rescue StandardError => e
        logger.error "DB::Dictate failed to update DB schema: #{e}"
        raise
      end
    end # module Dictate
  end # module DB
end # module Mimi
