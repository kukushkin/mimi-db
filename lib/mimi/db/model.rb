# frozen_string_literal: true

# NOTE: this is the way to create an abstract class that inherits from Sequel::Model
Mimi::DB::Model = Class.new(Sequel::Model)

module Mimi
  module DB
    class Model
      include Mimi::DB::Dictate

      self.require_valid_table = false
    end # class Model
  end # module DB
end # module Mimi
