module Mimi
  module DB
    module Lock
      class SqliteLock
        attr_reader :name, :name_digest, :lock_filename, :options, :timeout

        #
        # Timeout semantics:
        # nil -- wait indefinitely
        # 0   -- do not wait
        # <s> -- wait <s> seconds (can be Float)
        #
        def initialize(name, opts = {})
          @name = name
          @name_digest = Digest::SHA1.hexdigest(name).first(16)
          @options = opts
          @timeout =
            if opts[:timeout].nil?
              -1
            elsif opts[:timeout] <= 0
              0.100
            else
              opts[:timeout].to_f.round
            end
          db_filename = Pathname.new(Mimi::DB.module_options[:db_database]).expand_path
          @lock_filename = "#{db_filename}.lock-#{name_digest}"
          @lock_acquired = nil
          @file = nil
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
          @file = File.open(lock_filename, File::RDWR | File::CREAT, 0644)
          if timeout
            Timeout.timeout(timeout, Mimi::DB::Lock::NotAvailable) { @file.flock(File::LOCK_EX) }
          else
            @file.flock(File::LOCK_EX)
          end
          @lock_acquired = true
          true
        end

        #
        def release_lock!
          @file.flock(File::LOCK_UN) if @lock_acquired
          @file.close
          # NOTE: do not unlink file here, it leads to a potential race condition:
          # http://world.std.com/~swmcd/steven/tech/flock.html
          true
        end
      end # class SqliteLock
    end # module Lock
  end # module DB
end # module Mimi
