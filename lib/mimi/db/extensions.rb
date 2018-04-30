module Mimi
  module DB
    module Extensions
      def self.start
        install_primary_keys!
        install_bigint_foreign_keys!
      end

      def self.install_primary_keys!
        ca = ActiveRecord::ConnectionAdapters
        opts = Mimi::DB.module_options

        if ca.const_defined?(:CockroachDBAdapter) && opts[:db_primary_key_cockroachdb]
          ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = opts[:db_primary_key_cockroachdb]
        end

        if ca.const_defined?(:PostgreSQLAdapter) && opts[:db_primary_key_postgresql]
          ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = opts[:db_primary_key_postgresql]
        end

        if ca.const_defined?(:AbstractMysqlAdapter) && opts[:db_primary_key_mysql]
          ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key] = opts[:db_primary_key_mysql]
        end
      end

      def self.install_bigint_foreign_keys!
        ActiveRecord::Base.send(:include, Mimi::DB::ForeignKey)
      end
    end # module Extensions
  end # module DB
end # module Mimi
