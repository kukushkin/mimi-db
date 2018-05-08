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

        def field(name, opts)
          name = name.to_s
          raise "Cannot redefine field :#{name}" if @columns[name]
          if primary_key && (opts[:primary_key] || opts[:as] == :primary_key)
            raise "Cannot redefine primary key (:#{primary_key.name}) with :#{name}"
          end
          @columns[name] = Column.new(name, opts)
        end

        def index(columns, opts)
          case columns
          when String, Symbol
            columns = [columns.to_s]
          when Array
            unless columns.all? { |c| c.is_a?(String) || c.is_a?(Symbol) }
              raise "Invalid column reference in index definition [#{columns}]"
            end
            columns = columns.map(&:to_s)
          else
            raise 'Invalid columns argument to .index'
          end
          if columns == [primary_key]
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

        class Column
          DEFAULTS = {
            as: :string,
            limit: nil,
            primary_key: false,
            auto_increment: false,
            not_null: false,
            default: nil,
            sql_type: nil
          }.freeze

          attr_reader :name, :type, :params

          def initialize(name, opts)
            @name = name
            @type = opts[:as] || DEFAULTS[:as]
            type_defaults = Mimi::DB::Dictate.type_defaults(type)
            @params = DEFAULTS.merge(type_defaults).merge(opts)
          end

          def to_h
            {
              name: name,
              params: params.dup
            }
          end

          def ==(other)
            unless other.name == name
              raise ArgumentError, 'Cannot compare columns with different names'
            end
            equal = true
            equal &&= params[:as] == other.params[:as]
            equal &&= params[:limit] == other.params[:limit]
            equal &&= params[:primary_key] == other.params[:primary_key]
            # FIXME: auto_increment ignored
            equal &&= params[:not_null] == other.params[:not_null]
            equal &&= params[:default].to_s == other.params[:default].to_s
            # FIXME: sql_type ignored
            equal
          end
        end # class Column

        class Index
          DEFAULTS = {
            unique: false
          }.freeze

          attr_reader :name, :columns, :params

          def initialize(columns, params)
            @name = params[:name]
            @columns = columns
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
