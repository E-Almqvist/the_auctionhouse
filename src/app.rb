#!/usr/bin/ruby -w

require "sinatra"
require "sinatra/reloader" if ARGV[0] == "debug"
require "slim"
require "sqlite3"
require "sassc"

def get_random_subtitle
	subtitles = File.readlines "misc/subtitles.txt"
	subtitles.sample
end


get "/" do
	slim :index
end

get "/style.css" do
	sass :"stylesheets/style", style: :compressed
end
