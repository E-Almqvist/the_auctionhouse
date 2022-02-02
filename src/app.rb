#!/usr/bin/ruby -w

require "sinatra"
if ARGV[0] == "debug" then
	puts "Running app in debug mode..."
	require "sinatra/reloader"
end
require "slim"
require "sqlite3"

get "/" do
	"Test"
end
