DEFAULT_DB_PATH = "db/main.db"

class Table
	attr_reader :name
	attr_accessor :db

	def initialize(db, name)
		@db = db
		@name = name
		@sql_file = "sql/tables/#{name}.sql"
	end

	def create_table
		begin
			q = File.read @sql_file # get SQL script
			@db.query q # run query
		rescue Errno::ENOENT => err
			error "#{err}"	
		end
	end

	# these methods are private because they
	# are intended to be accessed through a
	# "Table Model".
	# See "db_models.rb"
	private def get(attr, filter="")
		@db.get(@name, attr, filter)
	end

	private def insert(data, filter="")
		@db.insert(@name, data, filter)
	end

	private def update(data, filter="")
		@db.update(@name, data, filter)
	end

	# sets or updates a specific field in the table
	private def set(attr, data, filter="") # slower but more lazy
		if @db.get(@name, attr, filter).length > 0 then
			@db.update(@name, data, filter)
		else
			@db.insert(@name, data, filter)
		end
	end
end

class Database # Database class
	attr_reader :name, :path 
	attr_accessor :tables
	def initialize(name, tables_names=[], db_path=DEFAULT_DB_PATH)
		@name = name
		@path = db_path

		@tables = []
		# generate table objects
		tables_names.each do |name|
			tbl = Table.new(self, name)
			@tables << tbl
		end
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

	def insert(table, data) # Inserts new data into the table
		entstr, valstr = gen_insert_query data.keys
		self.query( "INSERT INTO #{table} #{entstr} VALUES #{valstr}", *data.values )
	end
end
