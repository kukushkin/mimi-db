# frozen_string_literal: true

require 'sequel'

module Sequel
  class Database
    #
    # Fixed behaviour for Sequel's log_exception()
    #
    # Reason:
    #   * handled exceptions should not be logged as errors
    #   * unhandled exceptions will be logged at the application level
    #
    def log_exception(exception, message, *)
      text_message = "#{self.class}(#{exception.class}): #{exception.message}"
      logger_message = { m: text_message, sql: message }

      # In case logger does not support structured data, implement a #to_s method
      logger_message.define_singleton_method(:to_s) { text_message }
      log_each(:debug, logger_message)
    end
  end # class Database
end # module Sequel
