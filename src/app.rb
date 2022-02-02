#!/usr/bin/ruby -w

require "sinatra"
require "sinatra/reloader" if ARGV[0] == "debug"
require "slim"
require "sqlite3"

get "/" do
	"Test tesasdfhsdhjkft"
end
