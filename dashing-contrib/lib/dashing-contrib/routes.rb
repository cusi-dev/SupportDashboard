require 'sinatra'

get '/views/:widget?.html' do
  protected!
  tilt_html_engines.each do |suffix, engines|
    widget_name = params[:widget]
    file_name   = "#{widget_name}.#{suffix}"
    file_overrides = File.join(settings.root, 'widgets', widget_name, file_name)
    return engines.first.new(file_overrides).render if File.exist? file_overrides

    contrib_file = File.join(File.dirname(__FILE__), 'assets', 'widgets', widget_name, file_name)
    return engines.first.new(contrib_file).render if File.exist? contrib_file
  end
end

get '/api/states' do
  protected!
  content_type :json

  DashingContrib::Dashing.states.to_json
end

post '/api/history/save' do
  protected!
  content_type :json

  DashingContrib::History.save
  { message: 'done' }
end