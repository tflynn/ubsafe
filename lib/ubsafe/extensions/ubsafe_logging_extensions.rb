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

# Patch below changes all log-related times to UTC

require 'lockfile'

module Logging::Appenders
  class RollingFile < ::Logging::Appenders::IO


    def initialize( name, opts = {} )
      # raise an error if a filename was not given
      @fn = opts.getopt(:filename, name)
      raise ArgumentError, 'no filename was given' if @fn.nil?
      ::Logging::Appenders::File.assert_valid_logfile(@fn)

      # grab the information we need to properly roll files
      ext = ::File.extname(@fn)
      bn = ::File.join(::File.dirname(@fn), ::File.basename(@fn, ext))
      @rgxp = %r/\.(\d+)#{Regexp.escape(ext)}\z/
      @glob = "#{bn}.*#{ext}"
      @logname_fmt = "#{bn}.%d#{ext}"

      # grab our options
      @keep = opts.getopt(:keep, :as => Integer)
      @size = opts.getopt(:size, :as => Integer)

      @lockfile = if opts.getopt(:safe, false) and !::Logging::WIN32
        ::Lockfile.new(
            @fn + '.lck',
            :retries => 1,
            :timeout => 2
        )
      end

      code = 'def sufficiently_aged?() false end'
      @age_fn = @fn + '.age'

      case @age = opts.getopt(:age)
      when 'daily'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          now = Time.now.utc
          start = ::File.mtime(@age_fn)
          if (now.day != start.day) or (now - start) > 86400
            return true
          end
          false
        end
        CODE
      when 'weekly'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          if (Time.now.utc - ::File.mtime(@age_fn)) > 604800
            return true
          end
          false
        end
        CODE
      when 'monthly'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          now = Time.now.utc
          start = ::File.mtime(@age_fn)
          if (now.month != start.month) or (now - start) > 2678400
            return true
          end
          false
        end
        CODE
      when Integer, String
        @age = Integer(@age)
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          if (Time.now.utc - ::File.mtime(@age_fn)) > @age
            return true
          end
          false
        end
        CODE
      end
      meta = class << self; self end
      meta.class_eval code, __FILE__, __LINE__

      # if the truncate flag was set to true, then roll 
      roll_now = opts.getopt(:truncate, false)
      roll_files if roll_now

      super(name, open_logfile, opts)
    end

  end
end