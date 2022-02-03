DEFAULT_DB_PATH = "db/main.db"

require_relative "db_models.rb"

def db_handle 
	db = SQLite3::Database.new DEFAULT_DB_PATH
	db.results_as_hash = true
	return db
end
