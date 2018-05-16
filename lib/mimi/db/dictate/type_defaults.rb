# frozen_string_literal: true

module Mimi
  module DB
    module Dictate
      module TypeDefaults

        # Constructs a Proc that returns "<type>" or "<type>(n)" depending on whether the size is provided
        #
        DEF_OPT_SIZE_PROC = lambda do |type, default_size_suffix = ''|
          ->(p) { p[:size] ? { db_type: "#{type}(#{p[:size]})" } : { db_type: type + default_size_suffix } }
        end

        # Produces a "string" or "string(n)" depending on whether the size is provided
        #
        TYPE_STRING_PROC = DEF_OPT_SIZE_PROC.call('string')

        # Produces an "integer" or "integer(n)" depending on whether size is provided
        #
        TYPE_INTEGER_PROC = DEF_OPT_SIZE_PROC.call('integer')

        # Produces a "decimal", "decimal(p)" or "decimal(p,s)" depending on whether size is provided
        #
        TYPE_DECIMAL_PROC = lambda do |p|
          p[:size] ? { db_type: "decimal(#{[*p[:size]].join(',')})" } : { db_type: 'decimal' }
        end

        # Produces a "decimal", "decimal(p)" or "decimal(p, s)" depending on whether size is provided
        #
        TYPE_SQLITE_DECIMAL_PROC = lambda do |p|
          p[:size] ? { db_type: "decimal(#{[*p[:size]].join(', ')})" } : { db_type: 'decimal' }
        end

        # Produces a "numeric" or "numeric(p, s)" depending on whether size is provided
        #
        TYPE_POSTGRES_NUMERIC_PROC = lambda do |p|
          if p[:size]
            # p[:size] is either a number (precision) or an array (precision, scale)
            p1, p2 = [*p[:size]]
            { db_type: "numeric(#{p1},#{p2 || 0})" }
          else
            { db_type: 'numeric' }
          end
        end

        # Produces a "character varying" or "character varying(n)" depending on whether the size is provided
        #
        TYPE_POSTGRES_VARCHAR_PROC = lambda do |p|
          if p[:size]
            { db_type: "character varying(#{p[:size]})", sequel_type: :varchar }
          else
            { db_type: 'character varying(255)', sequel_type: :varchar }
          end
        end

        # Type converters, accept Sequel type (field as: ...) as a key,
        # return:
        # * a Hash of field params or
        # * a Proc returning a Hash of field params
        #
        TYPE_MAP = {
          default: {
          },
          sqlite: {
            bigint:    { db_type: 'bigint' },
            integer:   TYPE_INTEGER_PROC,
            int:       { db_type: 'integer', sequel_type: :integer },
            smallint:  { db_type: 'smallint' },

            decimal:   TYPE_SQLITE_DECIMAL_PROC,

            string:    DEF_OPT_SIZE_PROC.call('string'),
            varchar:   DEF_OPT_SIZE_PROC.call('varchar', '(255)'),
            text:      { db_type: 'text' },

            bytes:     { db_type: 'bytes' },
            bytea:     { db_type: 'bytes' },
            blob:      { db_type: 'bytes' },

            bool:      { db_type: 'bool' },
            boolean:   { db_type: 'bool' },

            date:      { db_type: 'date' },
            timestamp: { db_type: 'timestamp' },
            datetime:  { db_type: 'timestamp', sequel_type: :timestamp },

            float:      { db_type: 'double precision' }
          },
          postgres: {
            bigserial: { db_type: 'bigint', db_default: "nextval('tests_id_seq'::regclass)" },
            bigint:    { db_type: 'bigint' },
            integer:   { db_type: 'integer', sequel_type: :integer },
            int:       { db_type: 'integer', sequel_type: :integer },
            smallint:  { db_type: 'smallint' },

            decimal:   TYPE_POSTGRES_NUMERIC_PROC,

            string:    TYPE_POSTGRES_VARCHAR_PROC,
            varchar:   TYPE_POSTGRES_VARCHAR_PROC,
            text:      { db_type: 'text' },

            bytes:     { db_type: 'bytea', sequel_type: :bytea },
            bytea:     { db_type: 'bytea' },
            blob:      { db_type: 'bytea', sequel_type: :bytea },

            bool:      { db_type: 'boolean' },
            boolean:   { db_type: 'boolean' },

            date:      { db_type: 'date' },
            timestamp: { db_type: 'timestamp without time zone' },
            datetime:  { db_type: 'timestamp without time zone', sequel_type: :timestamp },

            float:      { db_type: 'double precision' }
          },
          cockroachdb: {
            bigserial: { db_type: 'bigint', db_default: 'unique_rowid()' },
            bigint:    { db_type: 'bigint' },
            integer:   { db_type: 'bigint' },
            int:       { db_type: 'bigint', sequel_type: :integer },
            smallint:  { db_type: 'bigint', sequel_type: :integer },

            decimal:   { db_type: 'numeric' },

            string:    { db_type: 'text', sequel_type: :string },
            varchar:   { db_type: 'text', sequel_type: :string },
            text:      { db_type: 'text' },

            bytes:     { db_type: 'bytea' },
            bytea:     { db_type: 'bytea', sequel_type: :bytes },
            blob:      { db_type: 'bytea', sequel_type: :bytes },

            bool:      { db_type: 'boolean' },
            boolean:   { db_type: 'boolean' },

            date:      { db_type: 'date' },
            timestamp: { db_type: 'timestamp without time zone' },
            datetime:  { db_type: 'timestamp without time zone', sequel_type: :timestamp },

            float:      { db_type: 'double precision' }
          }
        }
        #
        # The method infers column params based on column definition
        #
        # @param params [Hash]
        # @return [Hash]
        #
        def self.infer_params(params)
          type = params[:type].to_sym
          defaults = {
            db_type: type.to_s,
            sequel_type: type,
            primary_key: !!params[:primary_key],
            not_null: !!params[:primary_key],
            db_default: params[:default]
          }
          adapter_name = Mimi::DB.sequel_config[:adapter]
          raise "Failed to infer_params, adapter is not set: #{adapter_name}" unless adapter_name
          inferred_params = TYPE_MAP[adapter_name.to_sym][type] || TYPE_MAP[:default][type] || {}
          inferred_params = inferred_params.call(params) if inferred_params.is_a?(Proc)
          defaults.merge(inferred_params).merge(params)
        end
      end # module TypeDefaults
    end # module Dictate
  end # module DB
end # module Mimi
