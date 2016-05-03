module Mimi
  module DB
    module ForeignKey
      extend ActiveSupport::Concern

      class_methods do
        #
        # Explicitly specify a (bigint) foreign key
        #
        def foreign_key(name, opts = {})
          opts = { as: :integer, limit: 8 }.merge(opts)
          field(name, opts)
          index(name)
        end

        # Redefines .belongs_to() with explicitly specified .foreign_key
        #
        def belongs_to(name, opts = {})
          foreign_key(:"#{name}_id")
          # orig_belongs_to(name, opts)
          super
        end
      end
    end # module ForeignKey
  end # module DB
end # module Mimi
