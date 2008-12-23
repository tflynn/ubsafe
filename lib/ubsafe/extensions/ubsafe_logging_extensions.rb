module Logging
  module Layouts
    # Layout to be shared among all StandardizedLogger logging classes
    class UBSafeLoggerLayout < ::Logging::Layout

      attr_reader :app_name
      
      def initialize(configuration)
        @configuration = configuration
        @app_name = configuration[:log_identifier]
      end
      
      # call-seq:
      #    format( event )
      #
      # Returns a string representation of the given loggging _event_. See the
      #
      def format( event )
        msg = format_obj(event.data)
        severity_text = ::Logging::LNAMES[event.level]
        preamble = "#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}\tUTC\t[#{severity_text}]\t[#{hostname}]\t[#{app_name}]\t[#{$$}]\t"
        full_message =  preamble + (msg || '[nil]')
        full_message.gsub!(/\n/,' ')
        full_message += "\n" unless full_message =~ /\n$/
        return full_message
      end

    end
    
  end
end
