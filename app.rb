require 'rubygems'
require 'sinatra/base'
require 'haml'

class App < Sinatra::Base
  set :haml, :format => :html5

  get '/' do
    haml :index
  end
end
