def db
	dbbuf = SQLite3::Database.new DB_PATH
	dbbuf.results_as_hash = true
	dbbuf
end
	
class Entity 
	attr_reader :name, :path 
	attr_accessor :tables

	# Template
	private def create_table
		sql_file = "sql/tables/#{self.class.name}.sql"

		begin
			q = File.read sql_file # get SQL script
			self.db.query q # run query
		rescue Errno::ENOENT => err
			error "#{err}"	
		end
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

	private def query(q, *args) # query table with query string
		db.execute( q, *args )
	end

	private def get(attr, filter="", *args) # get data from table
		q = "SELECT #{attr} FROM #{self.class.table_name}" # create the query string
		q = apply_filter(q, filter)

		self.query q, *args # execute query
	end

	private def update(data, filter="") # Updates the table with specified data hash 
		q = "UPDATE #{self.class.table_name} SET #{self.gen_update_query(data.keys)}" 
		q = apply_filter(q, filter)

		self.query(q, *data.values )
	end

	private def insert(data) # Inserts new data into the table
		entstr, valstr = gen_insert_query data.keys
		self.query( "INSERT INTO #{self.class.table_name} #{entstr} VALUES #{valstr}", *data.values )
	end

	private def set(attr, data, filter="") # slower but more lazy
		if db.get(self.class.table_name, attr, filter).length > 0 then
			db.update(self.class.table_name, data, filter)
		else
			db.insert(self.class.table_name, data, filter)
		end
	end
end
