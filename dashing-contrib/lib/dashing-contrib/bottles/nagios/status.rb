module DashingContrib
  module Nagios
    module Status
      extend self

      def fetch(client, options = {})
        critical = client.service_status(default_critical_options.merge(options))
        warning  = client.service_status(default_warning_options.merge(options))
        ok       = client.service_status(default_ok_options.merge(options))
        unknown  = client.service_status(default_unknown_options.merge(options))
        ok.select! { |check| check['status'] == 'OK' }

        { critical: critical, warning: warning, unknown: unknown, ok: ok }
      end

      private
      def default_critical_options
        { :service_status_types => [:critical], :sort_type => :descending, :sort_option => :last_check }
      end

      def default_warning_options
        { :service_status_types => [:warning], :sort_type => :descending, :sort_option => :last_check }
      end

      def default_unknown_options
        { :service_status_types => [:unknown], :sort_type => :descending, :sort_option => :last_check }
      end

      def default_ok_options
        { :sort_option => :last_check, :sort_type => :descending }
      end
    end
  end
end