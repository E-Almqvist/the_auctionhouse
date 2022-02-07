DEFAULT_DB_PATH = "db/main.db"

class Table
	attr_reader :name
	attr_accessor :db

	def initialize(db, name, sql_file)
		@db = db
		@name = name
		@sql_file = sql_file
	end

	def create_table
		begin
			q = File.read @sql_file # get SQL script
			@db.query q # run query
		rescue Errno::ENOENT => err
			error "#{err}"	
		end
	end

	def get(attr, filter="")
		@db.get(@name, attr, filter)
	end

	def insert(data, filter="")
		@db.insert(@name, data, filter)
	end
end

require_relative "db_models.rb"

class Database # Database class
	attr_reader :name, :path 
	attr_accessor :tables
	def initialize(name, tables_names=[], db_path=DEFAULT_DB_PATH)
		@name = name
		@path = db_path

		@tables = []
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

	private def apply_filter(query, filter)
		if filter != "" then query += " WHERE #{filter}" end
		query
	end

	def query(q, *args) # query table with query string
		db.execute( q, *args )
	end

	def get(table, attr, filter="") # get data from table
		q = "SELECT #{attr} FROM #{table}" # create the query string
		q = apply_filter(q, filter)

		self.query query # execute query
	end

	def update(table, data, filter="") # Updates the table with specified data hash 
		q = "UPDATE #{table} SET #{self.gen_update_query(data.keys)}" 
		q = apply_filter(q, filter)

		self.query(q, *data.values )
	end

	def insert(table, data, filter="") # Inserts new data into the table
		entstr, valstr = gen_insert_query data.keys
		self.query( "INSERT INTO #{table} #{entstr} VALUES #{valstr}", *data.values )
	end

	# sets or updates a specific field in the table
	def set(table, attr, data, filter="") # slower but more lazy
		if self.get(table, attr, filter).length > 0 then
			self.update(table, data, filter)
		else
			self.insert(table, data, filter)
		end
	end
end
