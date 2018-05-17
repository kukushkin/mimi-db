# frozen_string_literal: true

# NOTE: this is the way to create an abstract class that inherits from Sequel::Model
Mimi::DB::Model = Class.new(Sequel::Model)

module Mimi
  module DB
    class Model
      include Mimi::DB::Dictate

      self.require_valid_table = false
      plugin :timestamps, create: :created_at, update: :updated_at, update_on_create: true
      plugin :validation_helpers

      # Keeps messages as error types, not human readable strings
      #
      def default_validation_helpers_options(type)
        { message: type }
      end

      def before_validation
        super
        call_hooks(:before_validation)
      end

      # Defines a hook the ActiveRecord way
      #
      # Example:
      #
      #   class A < Mimi::DB::Model
      #     before_validation :set_detaults
      #
      #     def set_defaults
      #       self.name = "John Doe"
      #     end
      #   end
      #
      def self.before_validation(method = nil, &block)
        if method && block
          raise ArgumentError, '.before_validation() cannot accept both method and a block'
        end
        block = -> { send(method) } if method
        register_hook(:before_validation, block)
      end

      private

      def self.registered_hooks(name)
        @registered_hooks ||= {}
        @registered_hooks[name] ||= []
      end

      def self.register_hook(name, block)
        registered_hooks(name) << block
      end

      def call_hooks(name)
        self.class.registered_hooks(name).each do |block|
          instance_eval(&block)
        end
      end
    end # class Model
  end # module DB
end # module Mimi
