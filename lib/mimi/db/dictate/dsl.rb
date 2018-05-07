# frozen_string_literal: true

module Mimi
  module DB
    module Dictate
      module DSL
        #
        # Declares a field on a model
        #
        # @example
        #   field :id,   as: :integer, limit: 8, primary_key: true, default: 'random_uid()'
        #
        #   field :name # default type is :string
        #   field :value, as: :decimal, precision: 10, scale: 3
        #   field :ref_code, as: :string, default: -> { random_ref_code() } # application default
        #
        def field(name, opts = {})
          opts = opts.dup
          # alter model behaviour based on field properties
          if opts[:default].is_a?(Proc)
            field_setup_default(name, opts[:default])
            opts.delete(:default)
          end

          # register field in the schema
          schema_definition.field(name, opts)
        end

        # Declares and index on one or several columns
        #
        # @param columns [Symbol,Array<Symbol>] one or several columns
        # @param opts [Hash] index options
        #
        # @example
        #   index :name
        #   index [:customer_id, :account_id], unique: true, name: 'idx_txs_on_customer_account'
        #
        def index(columns, opts = {})
          schema_definition.index(columns, opts)
        end

        def schema_definition
          unless self.respond_to?(:table_name)
            raise 'Mimi::DB::Dictate.schema_definition() expects .table_name, not invoked on a Model?'
          end
          Mimi::DB::Dictate.schema_definitions[table_name] ||=
            Mimi::DB::Dictate::SchemaDefinition.new(table_name)
        end

        private

        # Sets up a default as a block/Proc
        #
        def field_setup_default(name, block)
          before_validation on: :create do
            self.send :"#{name}=", block.call
          end
        end
      end # module DSL
    end # module Dictate
  end # module DB
end # module Mimi
