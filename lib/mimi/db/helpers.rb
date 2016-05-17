module Mimi
  module DB
    module Helpers
      #
      # Returns a list of model classes
      #
      # @return [Array<ActiveRecord::Base>]
      #
      def models
        ActiveRecord::Base.descendants
      end

      # Migrates the schema for known models
      #
      def migrate_schema!
        models.each(&:auto_upgrade!)
      end

      # Creates the database specified in the current configuration.
      #
      def create!
        ActiveRecord::Tasks::DatabaseTasks.root = Mimi.app_root_path
        ActiveRecord::Tasks::DatabaseTasks.create(Mimi::DB.active_record_config)
      end

      # Drops the database specified in the current configuration.
      #
      def drop!
        ActiveRecord::Tasks::DatabaseTasks.root = Mimi.app_root_path
        ActiveRecord::Tasks::DatabaseTasks.drop(Mimi::DB.active_record_config)
      end

      # Clears (but not drops) the database specified in the current configuration.
      #
      def clear!
        ActiveRecord::Tasks::DatabaseTasks.root = Mimi.app_root_path
        ActiveRecord::Tasks::DatabaseTasks.purge(Mimi::DB.active_record_config)
      end

      # Executes raw SQL, with variables interpolation.
      #
      # @example
      #   Mimi::DB.execute('insert into table1 values(?, ?, ?)', 'foo', :bar, 123)
      #
      def execute(statement, *args)
        sql = ActiveRecord::Base.send(:replace_bind_variables, statement, args)
        ActiveRecord::Base.connection.execute(sql)
      end
    end # module Helpers

    extend Mimi::DB::Helpers
  end # module DB
end # module Mimi
