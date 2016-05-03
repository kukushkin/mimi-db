module Mimi
  module DB
    module Extensions
      def self.start
        install_bigint_primary_keys!
        install_bigint_foreign_keys!
      end

      def self.install_bigint_primary_keys!
        ca = ActiveRecord::ConnectionAdapters

        if ca.const_defined? :PostgreSQLAdapter
          ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
        end

        if ca.const_defined? :AbstractMysqlAdapter
          ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key].gsub!(/int\(11\)/, 'bigint')
        end
      end

      def self.install_bigint_foreign_keys!
        ActiveRecord::Base.send(:include, Mimi::DB::ForeignKey)
      end
    end # module Extensions
  end # module DB
end # module Mimi
