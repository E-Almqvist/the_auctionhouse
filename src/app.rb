#!/usr/bin/ruby -w

require "sinatra"
require "sinatra/reloader" if ARGV[0] == "debug"
require "slim"
require "sqlite3"
require "sassc"

require_relative "database.rb"
require_relative "func.rb"

get "/" do
	slim :index
end

get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end



