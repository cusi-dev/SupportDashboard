require 'yaml'
require 'multi_json'

module DashingContrib
  module History
    extend self

    def history
      Sinatra::Application.settings.history
    end

    def history_file
      Sinatra::Application.settings.history_file
    end

    def save
      File.open(history_file, 'w') do |f|
        f.puts history.to_yaml
      end
    end

    def raw_event(event_name)
      return nil if history[event_name].nil?
      history[event_name].gsub(/^data:/, '')
    rescue
      nil
    end

    def json_event(event_name, default = nil)
      MultiJson.load(raw_event(event_name), { symbolize_keys: true })
    rescue
      default
    end

    def append_to(target_array=[], source_obj = {}, max_size=1000)
      target_array.shift while target_array.size >= max_size
      target_array << source_obj
    end
  end
end