require 'dashing-contrib/bottles/pingdom'

module DashingContrib
  module Jobs
    module PingdomUptime
      extend DashingContrib::RunnableJob

      def self.metrics(options)
        client = DashingContrib::Pingdom::Client.new(
          username: options[:username],
          password: options[:password],
          api_key:  options[:api_key]
        )

        user_opt = self.default_date_ranges.merge(options)

        id = user_opt[:check_id]
        current_uptime = client.uptime(id, user_opt[:default_date_range], user_opt[:now])
        first_uptime   = client.uptime(id, user_opt[:first_date_range], user_opt[:now])
        second_uptime  = client.uptime(id, user_opt[:second_date_range], user_opt[:now])
        status   = client.checks(id)

        # returns this dataset
        {
          current: current_uptime.to_s,
          first:  first_uptime.to_s,
          first_title: user_opt[:first_title],
          second: second_uptime.to_s,
          second_title: user_opt[:second_title],
          is_up: status[:check][:status] == 'up',
          current_response_time: status[:check][:lastresponsetime],
          last_downtime: ::DashingContrib::Time.readable_diff(::Time.at(status[:check][:lasterrortime]))
        }
      end

      def self.validate_state(metrics, options = {})
        return DashingContrib::RunnableJob::OK if metrics[:is_up]
        DashingContrib::RunnableJob::CRITICAL
      end

      private
      # a default date ranges to use for uptime metrics
      def self.default_date_ranges
        now_time = ::Time.now.to_i
        t24_hours  = 86400
        t1_month   = t24_hours * 4
        {
          now: now_time,
          default_date_range: now_time - t24_hours,
          first_title: '4 Months',
          first_date_range: now_time - (t1_month * 4),
          second_title: 'YTD',
          second_date_range: now_time - (t1_month * 12)
        }
      end
    end
  end
end