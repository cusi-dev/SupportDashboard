require 'dashing-contrib/bottles/nagios'

module DashingContrib
  module Jobs
    module NagiosList
      extend DashingContrib::RunnableJob


      # Returns format
      # {
      #   critical:[],
      #   warning:[],
      #   ok:[]
      # }
      def self.metrics(options)
        client = DashingContrib::Nagios::Client.new({
          username: options[:username],
          endpoint: options[:endpoint],
          password: options[:password],
          version: options[:version] || 3,
          time_format: options[:time_format] || 'iso8601'
        })

        client.status(options[:nagios_filter] || {})
      end

      def self.validate_state(metrics, options = {})
        return DashingContrib::RunnableJob::CRITICAL unless metrics[:critical].size.zero?
        return DashingContrib::RunnableJob::WARNING unless metrics[:warning].size.zero?
        DashingContrib::RunnableJob::OK
      end
    end
  end
end