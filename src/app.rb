#!/usr/bin/ruby -w

DEBUG = ARGV[0] == "debug"

require "sinatra"
require "sinatra/reloader" if DEBUG
require "slim"
require "sqlite3"
require "sassc"
require "colorize"

require_relative "debug.rb"
require_relative "lib/database.rb"
require_relative "func.rb"

load_tables = [
	"User",
	"Role"
]
db = Database.new("main", load_tables)

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
post "/user" do
	# create user
	redirect "/login"
end

post "/user/login" do
	# login user
	redirect "/"
end

