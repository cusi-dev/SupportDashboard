require 'active_support/all'
require 'dashing-contrib/version'

# configuration helpers
require 'dashing-contrib/configuration'

# history module and overall states management
require 'dashing-contrib/history'
require 'dashing-contrib/bottles/dashing'
require 'dashing-contrib/bottles/time'

# additional routes
require 'dashing-contrib/routes'

# contrib job extension
require 'dashing-contrib/runnable_job'
require 'dotenv'


module DashingContrib
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration if block_given?
    self.configure_sprockets
    Dotenv.load
  end

  private
  def self.configure_sprockets
    configuration.template_paths.each do |path|
      self.append_sprockets_path(path)
    end
  end

  def self.append_sprockets_path(path)
    puts "append to sprockets path: #{path}"
    puts Sinatra::Application.settings.sprockets

    Sinatra::Application.settings.sprockets.append_path(path)
  end
end


