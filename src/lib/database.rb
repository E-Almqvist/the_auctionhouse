def db
	dbbuf = SQLite3::Database.new DB_PATH
	dbbuf.results_as_hash = true
	dbbuf
end
	
class Entity 
	attr_reader :name, :path 
	attr_accessor :tables

	# Creates the table
	def self.init_table
		sql_file = "sql/tables/#{self.name}.sql"

		begin
			q = File.read sql_file # get SQL script
			self.db.query q # run query
		rescue Errno::ENOENT => err
			error "#{err}"	
		end
	end

	def self.gen_update_query(vars) # generates part of the update query string
		vars.join "= ?, "
	end

	def self.gen_insert_query(vars) # generates part of the insert query string
		entstr = "(#{vars.join ", "})"
		valstr = "(#{(["?"] * vars.length).join ", "})"

		return entstr, valstr
	end

	def self.apply_filter(query, filter)
		if filter != "" then query += " WHERE #{filter}" end
		query
	end

	def self.query(q, *args) # query table with query string
		db.execute( q, *args )
	end

	def self.get(attr, filter="", *args) # get data from table
		q = "SELECT #{attr} FROM #{self.name}" # create the query string
		q = apply_filter(q, filter)

		self.query q, *args # execute query
	end

	def self.update(data, filter="") # Updates the table with specified data hash 
		q = "UPDATE #{self.name} SET #{self.gen_update_query(data.keys)}" 
		q = apply_filter(q, filter)

		self.query(q, *data.values )
	end

	def self.insert(data) # Inserts new data into the table
		entstr, valstr = self.gen_insert_query data.keys
		self.query( "INSERT INTO #{self.name} #{entstr} VALUES #{valstr}", *data.values )
	end

	def self.set(attr, data, filter="") # slower but more lazy
		if self.get(attr, filter).length > 0 then
			self.update(data, filter)
		else
			self.insert(data, filter)
		end
	end
end
