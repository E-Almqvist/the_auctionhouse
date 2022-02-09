#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"
require "bcrypt"

require_relative "debug.rb"
require_relative "lib/database.rb"
require_relative "func.rb"

require_relative "db_init.rb"
require_relative "db_models.rb"

enable :sessions
db = db_init

def init_params(params={})
	g = Hash.new ""
	g.merge(params)
end


# Routes
get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end

get "/" do
	slim :index, locals: {params: init_params}
end

get "/login" do
	slim :"user/login", locals: {params: init_params}
end

get "/register" do
	slim :"user/register", locals: {params: init_params}
end

# API stuff
post "/user" do
	# create user
	email = params[:email]
	name = params[:name]
	password = params[:password]
	password_confirm = params[:password_confirm]

	redirect "/login"
end

post "/user/login" do
	# login user
	redirect "/"
end

