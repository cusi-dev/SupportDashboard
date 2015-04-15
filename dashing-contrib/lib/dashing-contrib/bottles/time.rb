require 'time_diff'

module DashingContrib
  class Time
    class << self
      def readable_diff(old_time, new_time = ::Time.now)
        t = ::Time.diff(new_time, old_time)
        "#{t[:day]}d #{t[:hour]}h #{t[:minute]}m"
      end
    end
  end
end