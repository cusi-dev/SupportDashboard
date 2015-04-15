require 'rest-client'
require 'multi_json'
require 'cgi'

module DashingContrib
  module Pingdom
    module Uptime
      extend self

      def calc(credentials, id, from_time, to_time, rounding = 2)
        payload = make_request(credentials, id, from_time, to_time)
        summary = payload[:summary][:status]
        up     = summary[:totalup]
        unkown = summary[:totalunknown]
        down   = summary[:totaldown]

        uptime = (up.to_f - (unkown.to_f + down.to_f)) * 100 / up.to_f
        uptime.round(rounding)
      end

      private
      def make_request(credentials, id, from_time, to_time)
        request_url = uptime_request_url(credentials, id, from_time, to_time)
        response = RestClient.get(request_url, { 'App-Key' => credentials.api_key })
        MultiJson.load(response.body, { symbolize_keys: true })
      end

      def uptime_request_url(credentials, id, from_time, to_time)
        "https://#{credentials.username}:#{credentials.password}@api.pingdom.com/api/2.0/summary.average/#{id}?from=#{from_time}&to=#{to_time}&includeuptime=true"
      end
    end
  end
end