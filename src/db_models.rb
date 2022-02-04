class TableModel  # Base model
	attr_reader :table_name
	def initialize(table_name)
		@table_name = table_name
	end

	private def gen_update_query(vars) # generates part of the update query string
		vars.join "= ?, "
	end

	private def gen_insert_query(vars) # generates part of the insert query string
		entstr = "(#{vars.join ", "})"
		valstr = "(#{(["?"] * vars.length).join ", "})"

		return entstr, valstr
	end

	private def query(q, *args) # query table with query string
		db_handle.execute( q, *args )
	end

	private def get(attr, filter="") # get data from table
		query = "SELECT #{attr} FROM #{@table_name} " # create the query string
		if filter != "" then query += "WHERE #{filter}" end

		self.query query # execute query
	end

	private def update(attr, data, filter="")
		self.query( "UPDATE #{@table_name} SET #{ self.gen_update_query(data.keys) } WHERE #{filter}", *data.values )
	end

	private def insert(attr, data, filter="")
		entstr, valstr = gen_insert_query data.keys
		self.query( "INSERT INTO #{@table_name} #{entstr} VALUES #{valstr}", *data.values )
	end

	private def set(attr, data={}, filter="") # slow, shouldn't really be used
		if self.get(attr, filter).length > 0 then
			self.update(attr, data, filter)
		else
			self.insert(attr, data, filter)
		end
	end
end


class User < TableModel
end
