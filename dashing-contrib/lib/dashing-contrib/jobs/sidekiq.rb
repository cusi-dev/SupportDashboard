require 'sidekiq/api'
module DashingContrib
  module Jobs
    module Sidekiq
      extend DashingContrib::RunnableJob

      def self.metrics(options)
        stats = ::Sidekiq::Stats.new
        metrics = [
            { label: 'Processed', value: stats.processed },
            { label: 'Failed',    value: stats.failed },
            { label: 'Retries',   value: stats.retry_size },
            { label: 'Dead',      value: stats.dead_size },
            { label: 'Enqueued',  value: stats.enqueued }
        ]
        { metrics: metrics }
      end

      def self.validate_state(metrics, options = {})
        default = { failed_warning_at: 100, failed_critical_at: 1000 }
        user_options = default.merge(options)

        failed_stats = metrics[:metrics].select { |v| v[:label] == 'Failed' }.first

        value = failed_stats[:value]
        return DashingContrib::RunnableJob::OK if value < user_options[:failed_warning_at]
        return DashingContrib::RunnableJob::WARNING if value >= user_options[:failed_warning_at] && value < user_options[:failed_critical_at]
        DashingContrib::RunnableJob::CRITICAL
      end
    end
  end
end