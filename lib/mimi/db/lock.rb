# frozen_string_literal: true
#
# NOTE: mimi/db/lock is NOT required automatically on require "mimi/db"
#
module Mimi
  module DB
    module Lock
      include Mimi::Core::Module

      default_options(
        default_lock_options: {
          # nil     -- wait indefinitely
          # 0       -- do not wait
          # <float> -- wait number of seconds
          timeout: nil
        }
      )

      def self.module_path
        Pathname.new(__dir__).join('lock')
      end

      def self.configure(*)
        super
        Mimi::DB.extend(self)
      end

      def self.start
        require_relative 'lock/postgresql_lock'
        require_relative 'lock/mysql_lock'
        require_relative 'lock/sqlite_lock'
        super
      end

      # Obtains a named lock
      #
      # @param [String,Symbol] name
      # @param [Hash] opts
      # @option opts [Numeric,nil] :timeout Timeout in seconds
      # @option opts [Boolean] :temporary Remove the lock
      #
      # @return [true] if the lock was obtained and the block executed
      # @return [Falsey] if the lock was NOT obtained
      #
      def lock(name, opts = {}, &block)
        lock!(name, opts, &block)
        true
      rescue NotAvailable
        nil
      end

      def lock!(name, opts = {}, &block)
        raise 'Not implemented'

        # FIXME: migrate Mimi::DB::Lock to Sequel

        opts = Mimi::DB::Lock.module_options[:default_lock_options].merge(opts.dup)
        adapter_name = ActiveRecord::Base.connection.adapter_name.downcase.to_sym
        case adapter_name
        when :postgresql, :empostgresql, :postgis
          Mimi::DB::Lock::PostgresqlLock.new(name, opts).execute(&block)
        when :mysql, :mysql2
          Mimi::DB::Lock::MysqlLock.new(name, opts).execute(&block)
        when :sqlite
          Mimi::DB::Lock::SqliteLock.new(name, opts).execute(&block)
        else
          raise "Named locks not supported by the adapter: #{adapter_name}"
        end
      end

      # Lock was not acquired error
      #
      class NotAvailable < RuntimeError
      end # class Error
      #
    end # module Lock
  end # module DB
end # module Mimi
