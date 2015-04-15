require 'dashing-contrib/bottles/dashing'
# Look at internal all available widgets and creates an overall state information
module DashingContrib
  module Jobs
    module DashingState
      extend DashingContrib::RunnableJob

      def self.metrics(options)
        DashingContrib::Dashing.states.merge({ ignore: true })
      end

      def self.validate_state(metrics, options = {})
        return DashingContrib::RunnableJob::CRITICAL if metrics[:critical] > 0
        return DashingContrib::RunnableJob::WARNING  if metrics[:warning] > 0
        DashingContrib::RunnableJob::OK
      end
    end
  end
end