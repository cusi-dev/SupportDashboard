require 'dashing-contrib'
require 'dashing'
DashingContrib.configure

configure do
<<<<<<< HEAD
  set :auth_token, '5D185034-8F8B-11E4-8E89-9540BC5C6E8B'
=======
  set :auth_token, 'YOUR_TOKEN_HERE'
>>>>>>> d33e2d64337990944312647af39f2b6e4e80c936

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
