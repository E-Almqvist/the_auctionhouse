DEFAULT_DB_PATH = "db/database.db"

class Database
	attr_reader :name, :db_path
	def initialize(name, db_path=DEFAULT_DB_PATH)
		@name = name
		@db_path = db_path 
	end

	def get_handle 
		db = SQLite3::Database.new @db_path
		db.results_as_hash = true
		return db
	end
end
