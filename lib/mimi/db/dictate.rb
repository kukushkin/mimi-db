require_relative 'dictate/dsl'
require_relative 'dictate/schema_definition'
require_relative 'dictate/schema_diff'
require_relative 'dictate/explorer'
require_relative 'dictate/migrator'
require_relative 'dictate/type_defaults'

module Mimi
  module DB
    module Dictate
      def self.included(base)
        base.extend Mimi::DB::Dictate::DSL
      end

      def self.start
      end

      def self.schema_definitions
        @schema_definitions ||= {}
      end

      def self.adapter_type
        Mimi::DB.connection.adapter_scheme
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
      #     logger: nil # will use Mimi::DB.logger
      #
      # @param opts [Hash]
      #
      def self.update_schema!(opts = {})
        logger = opts[:logger] || Mimi::DB.logger
        logger.debug 'Mimi::DB::Dictate started updating DB schema'
        t_start = Time.now
        Mimi::DB.all_table_names.each { |t| Mimi::DB::Dictate::Migrator.new(t, opts).run! }
        logger.debug 'Mimi::DB::Dictate finished updating DB schema (%.3fs)' % [Time.now - t_start]
      rescue StandardError => e
        logger.error "Mimi::DB::Dictate failed to update DB schema: #{e}"
        raise
      end

      # Diff existing DB schema and the target schema
      #
      # @param opts [Hash]
      # @return [Hash]
      #
      def self.diff_schema(opts = {})
        logger = opts[:logger] || Mimi::DB.logger
        diff = { add_tables: [], change_tables: [], drop_tables: [] }
        Mimi::DB.all_table_names.each do |t|
          m = Mimi::DB::Dictate::Migrator.new(t, opts)
          if m.from_schema && m.to_schema.nil?
            diff[:drop_tables] << t
          elsif m.from_schema && m.to_schema
            logger.debug "DB::Dictate comparing '#{t}'"
            t_diff = Mimi::DB::Dictate::SchemaDiff.diff(m.from_schema, m.to_schema)
            diff[:change_tables] << t_diff unless t_diff[:columns].empty? && t_diff[:indexes].empty?
          elsif m.from_schema.nil? && m.to_schema
            diff[:add_tables] << m.to_schema
          end
        end
        diff
      rescue StandardError => e
        logger.error "DB::Dictate failed to compare schema: #{e}"
        raise
      end
    end # module Dictate
  end # module DB
end # module Mimi
