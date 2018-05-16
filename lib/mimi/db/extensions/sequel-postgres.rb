require 'sequel/adapters/postgres'

class Sequel::Postgres::Database
  #
  # Fixed behaviour for Sequel's log_exception()
  #
  # Reason:
  #   * handled exceptions should not be logged as errors
  #   * unhandled exceptions will be logged at the application level
  #
  def log_exception(exception, message, *)
    log_each(:debug, { m: "#{self.class}(#{exception.class}): #{exception.message}", sql: message })
  end
end # class Sequel::Postgres::Database
