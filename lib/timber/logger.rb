require "logger"

module Timber
  # The Timber Logger behaves exactly like `::Logger`, except that it supports a transparent API
  # for logging structured messages. It ensures your log messages are communicated properly
  # with the Timber.io API.
  #
  # To adhere to our no code debt / no lock-in promise, the Timber Logger will *never* deviate
  # from the `::Logger` interface. That is, it will *never* add methods, or alter any
  # method signatures. This ensures Timber can be removed without consequence.
  #
  # == Examples
  #
  # The default logger interface is still preserved:
  #
  #   logger.info "Payment rejected for customer #{customer_id}"
  #
  # Although this works as expected, it is encouraged to log structured data:
  #
  #   logger.info message: "Payment rejected", type: :payment_rejected, data: {customer_id: customer_id, amount: 100}
  #
  # By providing `message`, `type`, and `data` keys Timber will classify this as a custom event.
  # This allows us to make assumptions about your data and enhance your experience.
  #
  # == Advanced example
  #
  # While the above examples provide a simple way to kick the tires, once you feel comfortable
  # we recommend defining typed events. Similar to how you'd do with exceptions. This provides
  # a stronger contract with downstream consumers (graphs, alerts, BI tools, etc):
  #
  #   class Event
  #     def to_hash
  #       hash = {}
  #       instance_variables.each { |var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
  #       hash
  #     end
  #     alias to_h to_hash
  #
  #     def to_timber_event
  #       Timber::Events::Custom.new(type: type, message: message, data: to_hash)
  #     end
  #
  #     def message; raise NotImplementedError.new; end
  #     def type; raise NotImplementedError.new; end
  #   end
  #
  #   class PaymentRejectedEvent < Event
  #     attr_accessor :customer_id, :amount
  #     def message; "Payment rejected for customer #{customer_id}"; end
  #     def type; :payment_rejected_event; end
  #   end
  #
  # The `Event` implementation is left to you, The only requirement is that it
  # responds to the `#to_timber_event` and returns the appropriate `Timber::Events::*` type.
  #
  # That's it! Happy logging!
  #
  #  _,-,
  # T_  |
  # ||`-'
  # ||
  # ||
  # ~~
  class Logger < ::Logger
    class Formatter # :nodoc:
      # Formatters get the formatted level from the logger.
      SEVERITY_MAP = {
        "DEBUG" => :debug,
        "INFO" => :info,
        "WARN" => :warn,
        "ERROR" => :error,
        "FATAL" => :datal,
        "UNKNOWN" => :unknown
      }

      private
        def build_log_entry(severity, time, progname, msg)
          level = SEVERITY_MAP.fetch(severity)
          context = CurrentContext.instance.snapshot
          event = Events.build(msg)
          if event
            LogEntry.new(level, time, progname, event.message, context, event)
          else
            LogEntry.new(level, time, progname, msg, context, nil)
          end
        end
    end

    # Structures your log messages into JSON.
    #
    #   logger = Timber::Logger.new(STDOUT)
    #   logger.formatter = Timber::JSONFormatter.new
    #
    # Example message:
    #
    #   {"level":"info","dt":"2016-09-01T07:00:00.000000-05:00","message":"My log message"}
    #
    class JSONFormatter < Formatter
      def call(severity, time, progname, msg)
        build_log_entry(severity, time, progname, msg).to_json()
      end
    end

    # Structures your log messages into Timber's hybrid format, which makes
    # it easy to read while also appending the appropriate metadata.
    #
    #   logger = Timber::Logger.new(STDOUT)
    #   logger.formatter = Timber::JSONFormatter.new
    #
    # Example message:
    #
    #   My log message @timber.io {"level":"info","dt":"2016-09-01T07:00:00.000000-05:00"}
    #
    class HybridFormatter < Formatter
      METADATA_CALLOUT = "@timber.io".freeze

      def call(severity, time, progname, msg)
        log_entry = build_log_entry(severity, time, progname, msg)
        metadata = log_entry.to_json(:except => [:message])
        "#{log_entry.message} #{METADATA_CALLOUT} #{metadata}"
      end
    end

    # Creates a new Timber::Logger instances. Accepts the same arguments as `::Logger.new`.
    # The only difference is that it default the formatter to `Timber::Logger::HybridFormatter`.
    def initialize(*args)
      super(*args)
      self.formatter = HybridFormatter.new
    end
  end
end