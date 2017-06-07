require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'psych'
require 'bcrypt'
require 'awesome_print'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

get '/' do
  'test'
end
