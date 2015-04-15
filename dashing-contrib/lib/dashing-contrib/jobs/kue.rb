require 'dashing-contrib/bottles/kue'
module DashingContrib
  module Jobs
    module Kue
      extend DashingContrib::RunnableJob

      def self.metrics(options)
        client = DashingContrib::Kue::Client.new({ endpoint: options[:endpoint] })
        stats = client.stats
        metrics = [
            { label: 'Processed',  value: stats[:complete_count] },
            { label: 'Processing', value: stats[:active_count] },
            { label: 'Failed',     value: stats[:failed_count] },
            { label: 'Queued',     value: stats[:inactive_count] },
            { label: 'Delayed',     value: stats[:delayed_count] }
        ]
        { metrics: metrics }
      end

      def self.validate_state(metrics, options = {})
        default = { failed_warning_at: 20, failed_critical_at: 100 }
        user_options = default.merge(options)

        failed_stats = metrics[:metrics].select { |v| v[:label] == 'Failed' }.first
        value = failed_stats[:value].to_i

        return DashingContrib::RunnableJob::OK if value < user_options[:failed_warning_at]
        return DashingContrib::RunnableJob::WARNING if value >= user_options[:failed_warning_at] && value < user_options[:failed_critical_at]
        DashingContrib::RunnableJob::CRITICAL
      end
    end
  end
end