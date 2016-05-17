module Mimi
  module DB
    module Lock
      class PostgresqlLock
        attr_reader :name, :name_uint64, :options, :timeout

        #
        # Timeout semantics:
        # nil -- wait indefinitely
        # 0   -- do not wait
        # <s> -- wait <s> seconds (can be Float)
        #
        def initialize(name, opts = {})
          @name = name
          @name_uint64 = Digest::SHA1.digest(name).unpack('q').first
          @options = opts
          @timeout =
            if opts[:timeout].nil?
              0
            elsif opts[:timeout] <= 0
              :nowait
            else
              opts[:timeout]
            end
        end

        def execute(&_block)
          ActiveRecord::Base.transaction(requires_new: true) do
            acquire_lock_with_timeout!
            yield if block_given?
          end
        end

        private

        # Returns current database connection setting for the lock timeout.
        # Value of 0 means the lock timeout is not set.
        #
        # @return [Float] Lock timeout in seconds
        #
        def lock_timeout
          result = Mimi::DB.execute('select setting from pg_settings where name = ?', :lock_timeout)
          value = result.first['setting'].to_i
          value = value.to_f / 1000 unless value == 0
          value
        end

        # Sets the current database connection setting for the lock timeout.
        # Value of 0 means the lock operations should never timeout.
        #
        # @param [Float,Fixnum] value Lock timeout in seconds
        #
        def lock_timeout=(value)
          raise ArgumentError, 'Numeric value expected as timeout' unless value.is_a?(Numeric)
          value = (value * 1000).to_i
          Mimi::DB.execute('update pg_settings set setting = ? where name = ?', value, :lock_timeout)
        end

        #
        def acquire_lock_with_timeout!
          unless timeout == :nowait
            old_timeout = lock_timeout
            self.lock_timeout = timeout unless timeout == old_timeout
          end
          if timeout == :nowait
            result = Mimi::DB.execute('select pg_try_advisory_xact_lock(?) as lock_acquired', name_uint64)
            lock_acquired = result.first['lock_acquired'] == 't'
            raise Mimi::DB::Lock::NotAvailable unless lock_acquired
          else
            begin
              Mimi::DB.execute('select pg_advisory_xact_lock(?)', name_uint64)
            rescue ActiveRecord::StatementInvalid
              raise Mimi::DB::Lock::NotAvailable
            end
            # NOTE: in case of a timeout the lock_timeout value will not be set back manually
            # .. it is expected to roll back with the transaction
            self.lock_timeout = old_timeout unless timeout == old_timeout
          end
          true
        end
      end # class PostgresqlLock
    end # module Lock
  end # module DB
end # module Mimi
