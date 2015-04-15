require 'rest-client'
require_relative './credentials'

module DashingContrib
  module Pingdom
    class Client
      # Initialize Pingdom client
      attr_accessor :credentials

      def initialize(options)
        @credentials = ::DashingContrib::Pingdom::Credentials.new(options)
      end

      def checks(id)
        ::DashingContrib::Pingdom::Checks.fetch(credentials, id)
      end

      def uptime(id, from_time, to_time)
        ::DashingContrib::Pingdom::Uptime.calc(credentials, id, from_time, to_time)
      end
    end
  end
end