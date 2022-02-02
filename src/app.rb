#!/usr/bin/ruby -w

require "sinatra"
require "sinatra/reloader" if ARGV[0] == "debug"
require "slim"
require "sqlite3"
require "sassc"

get "/" do
	slim :index
end

get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end
