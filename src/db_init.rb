LOAD_TABLES = [
	"User",
	"Role"
]

def db_init
	db = Database.new("main", LOAD_TABLES)
end
