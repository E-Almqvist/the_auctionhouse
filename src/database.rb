DEFAULT_DB_PATH = "db/main.db"

require_relative "db_models.rb"

class Table
	attr_reader :name
	attr_accessor :db
	def initialize(db, name)
		@db = db
		@name = name
	end
end

class Database # Database class
	attr_reader :name, :path 
	def initialize(name, table_structure, db_path=DEFAULT_DB_PATH)
		@name = name
		@path = db_path
		# generate table_structure if it doesn't exist

		@tables = {}
		# generate table objects
	end

	private def db
		dbbuf = SQLite3::Database.new @path 
		dbbuf.results_as_hash = true
		dbbuf
	end

	private def gen_update_query(vars) # generates part of the update query string
		vars.join "= ?, "
	end

	private def gen_insert_query(vars) # generates part of the insert query string
		entstr = "(#{vars.join ", "})"
		valstr = "(#{(["?"] * vars.length).join ", "})"

		return entstr, valstr
	end

	def query(q, *args) # query table with query string
		db.execute( q, *args )
	end

	def get(table, filter="") # get data from table
		query = "SELECT #{table} FROM #{table} " # create the query string
		if filter != "" then query += "WHERE #{filter}" end

		self.query query # execute query
	end

	def update(table, data, filter="") # Updates the table with specified data hash 
		self.query( "UPDATE #{table} SET #{ self.gen_update_query(data.keys) } WHERE #{filter}", *data.values )
	end

	def insert(table, data, filter="") # Inserts new data into the table
		entstr, valstr = gen_insert_query data.keys
		self.query( "INSERT INTO #{table} #{entstr} VALUES #{valstr}", *data.values )
	end

	# sets or updates a specific field in the table
	def set(table, data, filter="") # slower but more lazy
		if self.get(table, filter).length > 0 then
			self.update(table, data, filter)
		else
			self.insert(table, data, filter)
		end
	end
end
