require_relative "db_models.rb"

LOAD_TABLES = [
	User
]

def db_init
	db = Database.new("main", LOAD_TABLES)
end
