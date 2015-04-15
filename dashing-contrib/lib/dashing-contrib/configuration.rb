require 'pathname'

module DashingContrib
  class Configuration
    attr_accessor :template_paths

    def initialize
      @template_paths  = [File.expand_path("../", dir)]
    end

    # __dir__ is only supported >= ruby 2.0, use __FILE__ approach
    # Gem should support wide range of ruby versions
    def dir
      File.dirname(__FILE__)
    end
  end
end