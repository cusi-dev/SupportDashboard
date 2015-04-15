# Creates a overall framework to define a reusable job.
#
# A custom job module can extend `RunnableJob` and overrides `metrics` and `validate_state`
module DashingContrib
  module RunnableJob

    extend self
    WARNING  = 'warning'.freeze
    CRITICAL = 'critical'.freeze
    OK       = 'ok'.freeze

    class Context

      def initialize(interval, rufus_opts, event_name, user_options, this_module)
        @interval = interval
        @rufus_opts = rufus_opts
        @event_name = event_name
        @user_options = user_options
        @this_module = this_module
      end

      def schedule!
        _scheduler.every @interval, @rufus_opts do
          current_metrics = @this_module.metrics(@user_options)
          current_state   = @this_module.validate_state(current_metrics, @user_options)
          # including title and state
          additional_info = { state: current_state }
          additional_info[:title] = @user_options[:title] if @user_options[:title]
          send_event(@event_name, current_metrics.merge(additional_info))
        end
      end

      private
      def _scheduler
        SCHEDULER
      end
    end

    def run(options = {}, &block)
      user_options = _merge_options(options)
      interval     = user_options.delete(:every)
      scheduler_opts = user_options.delete(:scheduler) || {}

      ## Keep this for compatibility.
      #   Note: :first_in inside the :scheduler hash will override this.
      rufus_opt = {
        first_in: user_options[:first_in]
      }
      rufus_opt.merge!(scheduler_opts)

      event_name   = user_options.delete(:event)
      block.call if block_given?
      Context.new(interval, rufus_opt, event_name, user_options, self).schedule!
    end

    # Overrides this method to fetch and generate metrics
    # Return value should be the final metrics to be used in the user interface
    # Arguments:
    #   options :: options provided by caller in `run` method
    def metrics(options)
      {}
    end

    # Always return a common state, override this with your custom logic
    # Common states are WARNING, CRITICAL, OK
    # Arguments:
    #   metrics :: calculated metrics provided `metrics` method
    #   user_options :: hash provided by user options
    def validate_state(metrics, user_options)
      OK
    end

    private
    def _merge_options(options)
      raise ':event String is required to identify a job name' if options[:event].nil?
      _default_scheduler_options.merge(options)
    end

    def _default_scheduler_options
      {
        every: '30s',
        first_in: 0
      }
    end
  end
end

# dotenv doesn't seem to be loaded in dashing job
unless defined?(Dotenv)
  require 'dotenv'
  Dotenv.load
end
