#!/usr/bin/ruby -w

require "sinatra"
require "sinatra/reloader"
require "slim"
require "sqlite3"

get "/" do
	"Test"
end
