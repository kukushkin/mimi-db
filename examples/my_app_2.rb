# frozen_string_literal: true

puts "Requiring mimi/db, mimi/logger"
require 'mimi/db'
require 'mimi/logger'
puts "DONE"

CONFIG = {
  db_adapter: 'sqlite3',
  db_database: '../tmp/my_app_db',
  db_log_level: :debug
}.freeze

Mimi::DB.configure(CONFIG)
Mimi::DB.start

require_relative 'my_model'

require 'pp'
pp Mimi::DB.diff_schema
