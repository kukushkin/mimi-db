require 'mimi/core'
require 'sequel'

module Mimi
  module DB
    include Mimi::Core::Module

    default_options(
      require_files: 'app/models/**/*.rb',
      db_adapter: 'sqlite3',
      db_database: nil,
      db_host: nil,
      db_port: nil,
      db_username: nil,
      db_password: nil,
      db_log_level: :debug,
      db_pool: 15
      # db_encoding:
    )

    def self.module_path
      Pathname.new(__dir__).join('..').join('..').expand_path
    end

    def self.module_manifest
      {
        db_adapter: {
          desc: 'Database adapter ("sqlite3", "postgresql", "mysql", "cockroachdb" etc)',
          default: 'sqlite3'
        },
        db_database: {
          desc: 'Database name (e.g. "tmp/mydb")',
          # required
        },
        db_host: {
          desc: 'Database host',
          default: nil
        },
        db_port: {
          desc: 'Database port',
          default: nil
        },
        db_username: {
          desc: 'Database username',
          default: nil
        },
        db_password: {
          desc: 'Database password',
          default: nil
        },
        db_pool: {
          desc: 'Database connection pool size',
          default: 15
        },
        db_log_level: {
          desc: 'Logging level for database layer ("debug", "info" etc)',
          default: 'debug'
        }
      }
    end

    def self.configure(*)
      super
      if Mimi.const_defined?(:Application)
        @logger = Mimi::Application.logger
      end
    end

    def self.logger
      @logger ||= Mimi::Logger.new
    end

    # Returns active DB connection
    #
    # @return [Sequel::<...>::Database]
    #
    def self.connection
      @connection
    end

    def self.start
      Mimi::DB::Extensions.start
      @connection = Sequel.connect(sequel_config)
      Mimi.require_files(module_options[:require_files]) if module_options[:require_files]
      super
    end

    # Returns a standard Sequel adapter name converted from any variation of adapter names.
    #
    # @example
    #   sequel_config_canonical_adapter_name(:sqlite3) # => 'sqlite'
    #
    # @param adapter_name [String,Symbol]
    # @return [String]
    #
    def self.sequel_config_canonical_adapter_name(adapter_name)
      case adapter_name.to_s.downcase
      when 'sqlite', 'sqlite3'
        'sqlite'
      when 'postgres', 'postgresql'
        'postgres'
      when 'cockroach', 'cockroachdb'
        'cockroachdb'
      else
        adapter_name.to_s.downcase
      end
    end

    # Returns Sequel connection parameters
    #
    # @return [Hash]
    #
    def self.sequel_config
      {
        adapter: sequel_config_canonical_adapter_name(module_options[:db_adapter]),
        database: module_options[:db_database],
        host: module_options[:db_host],
        port: module_options[:db_port],
        user: module_options[:db_username],
        password: module_options[:db_password],
        encoding: module_options[:db_encoding],
        max_connections: module_options[:db_pool],
        sql_log_level: module_options[:db_log_level],
        logger: logger
      }
    end
  end # module DB
end # module Mimi

require_relative 'db/version'
require_relative 'db/extensions'
require_relative 'db/helpers'
require_relative 'db/foreign_key'
require_relative 'db/dictate'
require_relative 'db/model'
