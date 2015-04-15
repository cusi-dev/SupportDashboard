require 'cgi'

module DashingContrib
  module Pingdom
    class Credentials
      attr_accessor :api_key, :username, :password

      def initialize(options = {})
        user_options = default_options.merge(options)
        @api_key = user_options[:api_key] || missing_args(:api_key)
        @password = CGI.escape(user_options[:password]) || missing_args(:password)
        @username = CGI.escape(user_options[:username]) || missing_args(:username)
      end

      private
      def default_options
        {
            api_key: '',
            password: '',
            username: ''
        }
      end

      def missing_args(name)
        raise "Pingdom credentials requires #{name.to_s}"
      end
    end
  end
end