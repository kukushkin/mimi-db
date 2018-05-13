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

# class MyModel < ActiveRecord::Base
#   field :id, as: :integer, primary_key: true, not_null: true, autoincrement: true
#   field :name, as: :string, limit: 64
#   field :code, as: :string, default: -> { random_code }
#   field :value, as: :decimal, precision: 10, scale: 3

#   index :name

#   def self.random_code
#     SecureRandom.hex(16)
#   end
# end # class MyModel


class MyModel < Sequel::Model
  # include Mimi::DB::Dictate
  # field :id, as: :integer, primary_key: true, not_null: true, autoincrement: true
  # field :name, as: :string, limit: 64
  # field :code, as: :string, default: -> { random_code }
  # field :value, as: :decimal, precision: 10, scale: 3

  # index :name

  # def self.random_code
  #   SecureRandom.hex(16)
  # end
end # class MyModel


Mimi::DB.create_if_not_exist! # creates configured database
Mimi::DB.update_schema!
