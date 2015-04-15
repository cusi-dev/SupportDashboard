require 'dashing-contrib'
require 'dashing'
DashingContrib.configure

configure do
  set :auth_token, '5D185034-8F8B-11E4-8E89-9540BC5C6E8B'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
