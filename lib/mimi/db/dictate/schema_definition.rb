# frozen_string_literal: true

module Mimi
  module DB
    module Dictate
      class SchemaDefinition
        attr_reader :table_name, :columns, :indexes

        def initialize(table_name)
          @table_name = table_name
          @columns = {}
          @indexes = []
        end

        # Declares a field
        #
        # Example:
        #   field :s1, as: :string
        #   field :s2, type: :string, size: 64
        #   field :v1, as: :decimal, size: 10      # precision: 10
        #   field :v2, as: :decimal, size: [10, 3] # precision: 10, scale: 3
        #
        #
        def field(name, opts)
          name = name.to_sym
          raise "Cannot redefine field :#{name}" if @columns[name]
          opts_type = opts[:type] || opts[:as]
          if primary_key && (opts[:primary_key] || opts_type == :primary_key)
            raise "Cannot redefine primary key (:#{primary_key.name}) with :#{name}"
          end
          @columns[name] = Column.new(name, opts)
        end

        # Declares an index
        #
        # Example:
        #   index :name
        #   index [:first_name, :last_name]
        #   index :ref_code, unique: true
        #
        # @param columns [String,Symbol,Array<String,Symbol>] columns to index on
        # @param opts [Hash] index parameters (:unique, :name etc)
        #
        def index(columns, opts)
          case columns
          when String, Symbol
            columns = [columns.to_sym]
          when Array
            unless columns.all? { |c| c.is_a?(String) || c.is_a?(Symbol) }
              raise "Invalid column reference in index definition [#{columns}]"
            end
            columns = columns.map(&:to_sym)
          else
            raise 'Invalid columns argument to .index'
          end
          if columns == [primary_key.name]
            # TODO: warn the primary key index is ignored
          end
          @indexes << Index.new(columns, opts)
        end

        # Returns primary key column
        #
        # @return [Mimi::DB::Dictate::SchemaDefinition::Column]
        #
        def primary_key
          pk = columns.values.find { |c| c.params[:primary_key] }
          # raise "Primary key is not defined on '#{table_name}'" unless pk
          pk
        end

        def to_h
          {
            table_name: table_name,
            columns: columns.values.map(&:to_h),
            indexes: indexes.map(&:to_h)
          }
        end

        # Represents a column in schema definition
        #
        class Column
          DEFAULT_TYPE = :string

          attr_reader :name, :type, :sequel_type, :params

          # Creates a Column object
          #
          # @param name [String,Symbol]
          # @param opts [Hash]
          #
          def initialize(name, opts)
            @name = name.to_sym
            @params = opts.dup
            @params[:type] ||= @params[:as] || DEFAULT_TYPE
            @params = Mimi::DB::Dictate::TypeDefaults.infer_params(@params)
            @type = @params[:type]
            @sequel_type = @params[:sequel_type]
          end

          def to_h
            {
              name: name,
              params: params.dup
            }
          end

          def to_sequel_params
            p = params.dup.except(:type, :as)
            p[:null] = !p[:not_null] if p.key?(:not_null)
            p
          end

          def to_s
            public_params = params.only(
              :type, :primary_key, :auto_increment, :not_null, :default, :size
            ).select { |_, v| v }.to_h
            public_params = public_params.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
            "#{name}(#{public_params})"
          end

          def ==(other)
            unless other.name == name
              raise ArgumentError, 'Cannot compare columns with different names'
            end
            equal = true
            equal &&= params[:db_type] == other.params[:db_type]
            equal &&= params[:primary_key] == other.params[:primary_key]
            equal &&= params[:not_null] == other.params[:not_null]
            equal &&= params[:db_default].to_s == other.params[:db_default].to_s
            equal
          end
        end # class Column

        # Represents an index in schema definition
        #
        class Index
          DEFAULTS = {
            unique: false
          }.freeze

          attr_reader :name, :columns, :params

          # Creates an Index object
          #
          # @param columns [Array<String,Symbol>]
          # @param params [Hash]
          #
          def initialize(columns, params)
            @name = params[:name]
            @columns = columns.map(&:to_sym)
            @params = DEFAULTS.merge(params)
          end

          def to_h
            {
              name: name,
              columns: columns,
              params: params.dup
            }
          end
        end # class Index
      end # class SchemaDefinition
    end # module Dictate
  end # module DB
end # module Mimi
