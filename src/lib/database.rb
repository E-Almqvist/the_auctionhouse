def db
	dbbuf = SQLite3::Database.new DB_PATH
	dbbuf.results_as_hash = true
	dbbuf
end

class EntityModel
	attr_reader :id, :data

	def initialize(data)
		@id = data["id"]
		@data = data
	end

	# Initializes the table on startup 
	# @return [void]
	def self.init_table
		sql_file = "sql/tables/#{self.name}.sql"

		begin
			q = File.read sql_file # get SQL script
			self.query q # run query
		rescue Errno::ENOENT => err
			Console.error "#{err}"	
		end
	end

	# Generates a sql update query filter
	# @param [Array<String>] vars strings that are the sql table attributes
	# @return [String] Query filter
	def self.gen_update_query(vars) # generates part of the update query string
		out = vars.join " = ?, "
		out += " = ?"
	end

	# Generates a SQL insert query filter 
	# @param [Array<String>] vars strings that are the SQL table attributes
	# @return [String] Query filter
	def self.gen_insert_query(vars) 
		entstr = "(#{vars.join ", "})"
		valstr = "(#{(["?"] * vars.length).join ", "})"

		return entstr, valstr
	end

	# Applies a filter to a query
	# @param [String] query The query
	# @param [String] filter The filter
	# @return [String] Full query SQL string with filter
	def self.apply_filter(query, filter)
		if filter != "" then query += " WHERE #{filter}" end
		query
	end

	# Query the table with given SQL query string
	# @param [String] q The query
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [Hash] Query result
	def self.query(q, *args) 
		Console.debug("Running SQL -> #{q}", *args)
		begin
			db.execute( q, args )
		rescue SQLite3::SQLException => err
			Console.error "SQL exception: #{err}", q
		end
	end

	# Extended query that also returns database instance
	# @see EntityModel#query
	# @param [String] q The query
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [SQLite3::Database] SQLite3 Database instance
	# @return [Hash] Query result
	def self.equery(q, *args)
		Console.debug("Running extended SQL -> #{q}", *args)
		begin
			dbbuf = db
			resp = dbbuf.execute( q, args )
			return dbbuf, resp
		rescue SQLite3::SQLException => err
			Console.error "SQL exception: #{err}", q
		end
	end

	# Get data from table with given filter
	# @see EntityModel#query
	# @param [String] attr The table attribute name
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [Hash] Query result
	def self.get(attr, filter="", *args) # get data from table
		q = "SELECT #{attr} FROM #{self.name}" # create the query string
		q = apply_filter(q, filter)

		self.query q, *args # execute query
	end

	# Update data in table with given filter
	# @see EntityModel#equery
	# @param [Hash] data Hash of new data
	# @param [String] filter Query filter
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [Hash] Query result
	def self.update(data, filter="", *args) # Updates the table with specified data hash 
		q = "UPDATE #{self.name} SET #{self.gen_update_query(data.keys)}" 
		q = apply_filter(q, filter)
		self.query(q, *data.values, *args)
	end

	# Update data in table where id = something
	# @see EntityModel#update
	# @param [Integer] id Selected primary key
	# @param [Hash] data Hash of new data
	# @return [Hash] Query result
	def self.edit(id, data)
		self.update(data, "id=?", id)
	end

	# Insert data in table 
	# @see EntityModel#equery
	# @param [Hash] data Hash of new data
	# @return [Integer] New primary key that was generated
	# @return [String] Response string
	def self.insert(data) # Inserts new data into the table
		entstr, valstr = self.gen_insert_query data.keys
		begin
			dbbuf, resp = self.equery( "INSERT INTO #{self.name} #{entstr} VALUES #{valstr}", *data.values )
			newid = dbbuf.last_insert_row_id
		rescue SQLite3::ConstraintException
			resp = "Constraint Exception! Duplicate item."
		end
		return newid, resp
	end

	# Delete entry with given filter
	# @see EntityModel#query
	# @param [String] filter Query filter
	# @param [Array] args Variable values etc
	def self.delete(filter="", *args)
		q = "DELETE FROM #{self.name}"
		q = self.apply_filter(q, filter)
		self.query q, *args
	end

	# Checks if primary key exists in table
	# @param [Integer] id The primary key
	# @return [Bool] If it exists or not
	def self.exists?(id)
		resp = self.get "id", "id = ?", id
		resp.length > 0
	end

	# Find object by id
	# @param [Integer] id Primary key
	# @return [Object] Model object
	def self.find_by_id(id)
		data = self.get("*", "id = ?", id).first
		data && self.new(data)
	end

	# Get all ids in table
	# @param [String] filter Query filter
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [Array<Integer>] Array of all the primary keys
	def self.get_all_ids filter="", *args
		ids = self.get "id", *args
		ids.map! {|k, id| id.to_i}
	end

	# Get all objects in table
	# @param [String] filter Query filter
	# @param [Array] args Other arguments (such as variable values etc)
	# @return [Array<Object>] Array of all the primary keys
	def self.get_all filter="", *args
		data = self.get "*", filter, *args
		data && data.map! {|r| self.new(r)}
	end
end

=begin
class RelationModel < EntityModel # TODO: make this work
	def self.tables = nil

	def self.get_relation(s_ent, table, filter="", *args)
		q = "SELECT #{s_ent} FROM #{self.name}"
		q = self.apply_filter(q, filter)
		ents = self.get q, *args

		ents.each do |ent|
			table.find_by_id ent["id"].to_i
		end
	end
end
=end

