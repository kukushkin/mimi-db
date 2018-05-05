module Mimi
  module DB
    module Extensions
      def self.start
        # install DB::Dictate
        ActiveRecord::Base.send(:include, Mimi::DB::Dictate)

        # FIXME: refactor DSL for primary/foreign keys
        # install_primary_keys!
        # install_bigint_foreign_keys!
      end

      def self.install_bigint_foreign_keys!
        # ActiveRecord::Base.send(:include, Mimi::DB::ForeignKey)
      end
    end # module Extensions
  end # module DB
end # module Mimi
