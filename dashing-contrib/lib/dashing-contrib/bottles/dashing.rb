require 'dashing-contrib/history'

# Extracts overall state of dashing widgets
# This is useful for overall view of the monitoring system
module DashingContrib
  module Dashing

    def self.states
      detailed_status = {}
      ok_count = 0
      warning_count = 0
      critical_count = 0

      DashingContrib::History.history.each do |key, value|
        payload = DashingContrib::History.json_event(key, {})
        state   = payload[:state] || 'ok'
        title   = payload[:title] || key

        unless payload[:ignore]
          ok_count = ok_count + 1             if state == 'ok'
          warning_count = warning_count + 1   if state == 'warning'
          critical_count = critical_count + 1 if state == 'critical'

          detailed_status[key] = {
            state: state,
            title: title,
            updated_at: payload[:updatedAt]
          }
        end
      end

      {
        ok: ok_count,
        warning: warning_count,
        critical: critical_count,
        detailed_status: detailed_status
      }
    end
  end
end