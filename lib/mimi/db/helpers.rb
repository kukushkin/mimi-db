module Mimi
  module DB
    module Helpers
      #
      # Returns a list of model classes
      #
      # @return [Array<ActiveRecord::Base>]
      #
      def models
        Mimi::DB::Model.descendants
      end

      # Returns a list of table names defined in models
      #
      # @return [Array<String>]
      #
      def model_table_names
        models.map(&:table_name).uniq
      end

      # Returns a list of all DB table names
      #
      # @return [Array<String>]
      #
      def db_table_names
        Mimi::DB.connection.tables
      end

      # Returns a list of all discovered table names,
      # both defined in models and existing in DB
      #
      # @return [Array<String>]
      #
      def all_table_names
        (model_table_names + db_table_names).uniq
      end

      # Updates the DB schema.
      #
      # Brings DB schema to a state defined in models.
      #
      # Default options from Migrator::DEFAULTS:
      #     destructive: {
      #       tables: false,
      #       columns: false,
      #       indexes: false
      #     },
      #     dry_run: false,
      #     logger: nil # will use ActiveRecord::Base.logger
      #
      # @example
      #   # only detect and report planned changes
      #   Mimi::DB.update_schema!(dry_run: true)
      #
      #   # modify the DB schema, including all destructive operations
      #   Mimi::DB.update_schema!(destructive: true)
      #
      def update_schema!(opts = {})
        opts[:logger] ||= Mimi::DB.logger
        Mimi::DB::Dictate.update_schema!(opts)
      end

      # Discovers differences between existing DB schema and target schema
      # defined in models.
      #
      # @example
      #   Mimi::DB.diff_schema
      #
      #   # =>
      #   # {
      #   #   add_tables: [<table_schema1>, <table_schema2> ...],
      #   #   change_tables: [
      #   #     { table_name: ...,
      #   #       columns: {
      #   #         "<column_name1>" => {
      #   #           from: { <column_definition or nil> },
      #   #           to: { <column_definition or nil> }
      #   #         }
      #   #       }
      #   #     }, ...
      #   #   ],
      #   #   drop_tables: [<table_name1>, ...]
      #   # }
      # @return [Hash]
      #
      def diff_schema(opts = {})
        opts[:logger] ||= Mimi::DB.logger
        Mimi::DB::Dictate.diff_schema(opts)
      end

      # Creates the database specified in the current configuration.
      #
      def create!
        raise "Not implemented"

        db_adapter = Mimi::DB.active_record_config['adapter']
        db_database = Mimi::DB.active_record_config['database']
        slim_url = "#{db_adapter}//<host>:<port>/#{db_database}"
        Mimi::DB.logger.info "Mimi::DB.create! creating database: #{slim_url}"
        original_stdout = $stdout
        original_stderr = $stderr
        $stdout = StringIO.new
        $stderr = StringIO.new
        ActiveRecord::Tasks::DatabaseTasks.root = Mimi.app_root_path
        ActiveRecord::Tasks::DatabaseTasks.create(Mimi::DB.active_record_config)
        Mimi::DB.logger.debug "Mimi::DB.create! out:#{$stdout.string}, err:#{$stderr.string}"
      ensure
        $stdout = original_stdout
        $stderr = original_stderr
      end

      # Tries to establish connection, returns true if the database exist
      #
      def database_exist?
        Mimi::DB.connection.test_connection
        true
      rescue StandardError => e
        Mimi::DB.logger.error "DB: database_exist? failed with: #{e}"
        false
      end

      # Creates the database specified in the current configuration, if it does NOT exist.
      #
      def create_if_not_exist!
        if database_exist?
          Mimi::DB.logger.debug 'Mimi::DB.create_if_not_exist! database exists, skipping...'
          return
        end
        create!
      end

      # Drops the database specified in the current configuration.
      #
      def drop!
        raise "Not implemented"
      end

      # Clears (but not drops) the database specified in the current configuration.
      #
      def clear!
        Mimi::DB.start
        db_table_names.each do |table_name|
          Mimi::DB.logger.info "Mimi::DB dropping table: #{table_name}"
          Mimi::DB.connection.drop_table(table_name)
        end
      end

      # Executes raw SQL, with variables interpolation.
      #
      # @example
      #   Mimi::DB.execute('insert into table1 values(?, ?, ?)', 'foo', :bar, 123)
      #
      def execute(statement, *args)
        sql = Sequel.fetch(statement, *args).sql
        Mimi::DB.connection.run(sql)
      end

      # Executes a block with a given DB log level
      #
      # @param log_level [Symbol,nil] :debug, :info etc
      #
      def with_log_level(log_level, &_block)
        current_log_level = Mimi::DB.connection.sql_log_level
        Mimi::DB.connection.sql_log_level = log_level
        yield
      ensure
        Mimi::DB.connection.sql_log_level = current_log_level
      end
    end # module Helpers

    extend Mimi::DB::Helpers
  end # module DB
end # module Mimi
