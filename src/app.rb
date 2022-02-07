#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"

require_relative "debug.rb"
require_relative "database.rb"
require_relative "db_models.rb"
require_relative "func.rb"

enable :sessions

get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end

get "/" do
	slim :index
end

get "/login" do
	slim :"user/login"
end

get "/register" do
	slim :"user/register"
end

# API stuff
post "/user/login" do
	# login user
	redirect "/"
end

post "/user/new" do
	# create user
	redirect "/login"
end
