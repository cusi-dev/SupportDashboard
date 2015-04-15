require 'nagiosharder'

module DashingContrib
  module Nagios
    class Client
      attr_reader :client

      def initialize(options = {})
        @client = NagiosHarder::Site.new(options[:endpoint], options[:username], options[:password], options[:version], options[:time_format])
      end

      def status(options = {})
        ::DashingContrib::Nagios::Status.fetch(client, options)
      end
    end
  end
end