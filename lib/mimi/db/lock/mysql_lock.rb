module Mimi
  module DB
    module Lock
      class MysqlLock
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
              -1
            elsif opts[:timeout] <= 0
              0
            else
              opts[:timeout].to_f.round
            end
        end

        def execute(&_block)
          ActiveRecord::Base.transaction(requires_new: true) do
            begin
              acquire_lock_with_timeout!
              yield if block_given?
            ensure
              release_lock!
            end
          end
        end

        private

        #
        def acquire_lock_with_timeout!
          result = Mimi::DB.execute('select get_lock(?, ?) as lock_acquired', name, timeout)
          lock_acquired = result.first[0] == 1
          raise Mimi::DB::Lock::NotAvailable unless lock_acquired
          true
        end

        #
        def release_lock!
          Mimi::DB.execute('select release_lock(?)', name)
          true
        end
      end # class MysqlLock
    end # module Lock
  end # module DB
end # module Mimi
