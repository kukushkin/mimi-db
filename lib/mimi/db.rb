require 'mimi/core'
require 'active_record'
require 'mini_record'

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
      db_log_level: :info,
      db_pool: 15
      # db_encoding:
    )

    def self.module_path
      Pathname.new(__dir__).join('..').join('..').expand_path
    end

    def self.module_manifest
      {
        db_adapter: {
          desc: 'Database adapter ("sqlite3", "postgresql", "mysql" etc)',
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
          default: 'info'
        }
      }
    end

    def self.configure(*)
      super
      ActiveRecord::Base.logger = logger
      ActiveRecord::Base.configurations = { 'default' => active_record_config }
      # ActiveRecord::Base.raise_in_transactional_callbacks = true
    end

    def self.logger
      @logger ||= Mimi::Logger.new(level: module_options[:db_log_level])
    end

    def self.start
      ActiveRecord::Base.establish_connection(:default)
      Mimi::DB::Extensions.start
      Mimi.require_files(module_options[:require_files]) if module_options[:require_files]
      super
    end

    def self.active_record_config
      {
        adapter: module_options[:db_adapter],
        database: module_options[:db_database],
        host: module_options[:db_host],
        port: module_options[:db_port],
        username: module_options[:db_username],
        password: module_options[:db_password],
        encoding: module_options[:db_encoding],
        pool: module_options[:db_pool],
        reaping_frequency: 15
      }.stringify_keys
    end
  end # module DB
end # module Mimi

require_relative 'db/version'
require_relative 'db/extensions'
require_relative 'db/helpers'
require_relative 'db/foreign_key'
