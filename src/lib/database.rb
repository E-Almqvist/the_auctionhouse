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

	# Creates the table
	def self.init_table
		sql_file = "sql/tables/#{self.name}.sql"

		begin
			q = File.read sql_file # get SQL script
			self.query q # run query
		rescue Errno::ENOENT => err
			Console.error "#{err}"	
		end
	end

	def self.gen_update_query(vars) # generates part of the update query string
		out = vars.join " = ?, "
		out += " = ?"
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
		Console.debug("Running SQL -> #{q}", *args)
		begin
			db.execute( q, args )
		rescue SQLite3::SQLException => err
			Console.error "SQL exception: #{err}", q
		end
	end

	def self.get(attr, filter="", *args) # get data from table
		q = "SELECT #{attr} FROM #{self.name}" # create the query string
		q = apply_filter(q, filter)

		self.query q, *args # execute query
	end

	def self.update(data, filter="", *args) # Updates the table with specified data hash 
		q = "UPDATE #{self.name} SET #{self.gen_update_query(data.keys)}" 
		q = apply_filter(q, filter)
		self.query(q, *data.values, *args)
	end

	def self.insert(data) # Inserts new data into the table
		entstr, valstr = self.gen_insert_query data.keys
		r = self.query( "INSERT INTO #{self.name} #{entstr} VALUES #{valstr}", *data.values )
		newid = db.last_insert_row_id
		return newid, r
	end

	def self.set(attr, data, filter="") # slower but more lazy
		if self.get(attr, filter).length > 0 then
			self.update(data, filter)
		else
			self.insert(data, filter)
		end
	end

	def self.get_all(ents="*")
		self.query "SELECT #{ents} FROM #{self.name}"
	end

	def self.exists?(id)
		resp = self.get "id", "id = ?", id
		resp.length > 0
	end

	def self.find_by_id(id)
		data = self.get("*", "id = ?", id).first
		data && self.new(data)
	end
end

class RelationModel < EntityModel # TODO: make this work
	def self.tables = nil

	def self.get_relation(id)
		roleids = self.get "role_id", "user_id = ?", user_id
		roles = roleids.map do |ent| 
			Role.find_by_id(ent["role_id"].to_i)
		end
	end
end
