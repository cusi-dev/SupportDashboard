require 'rest-client'
require 'multi_json'
module DashingContrib
  module Kue
    class Client
      attr_reader :endpoint

      # Creates a new Kue Client
      # Arguments:
      # endpoint :: endpoint of Kue web interface
      #
      def initialize(options = {})
        @endpoint = options[:endpoint]
      end

      # Returns a stats summary of Kue status in following format
      #
      # Tries to transform from camalCase JSON key to ruby
      # friendly symbal underscore format
      #
      #    {
      #      :inactive_count: 235,
      #      :complete_count: 29426,
      #      :active_count: 4,
      #      :failed_count: 11,
      #      :delayed_count: 0,
      #      :work_time: 778205330
      #    }
      #
      def stats
        payload = {}
        get_request('stats').each do |key, value|
          payload[:"#{key.underscore}"] = value
        end
        payload
      end

      private
      def get_request(uri)
        response = RestClient.get("#{endpoint}/#{uri}")
        MultiJson.load(response.body)
      end

    end
  end
end