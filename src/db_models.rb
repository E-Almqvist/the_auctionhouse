class TableModel  # Base model
	attr_reader :table_name
	def initialize(table_name)
		@table_name = table_name
	end

	private def gen_update_query(varhash, values)
		qstr = ""
		varhash.each do |val, var|
			qstr += "#{var} = #{val}, "
		end

		return qstr 
	end

	private def get(attr, filter="")
		db = db_handle # get the db handle
		query = "SELECT #{attr} FROM #{@table_name} " # create the query string
		if filter != "" then query += "WHERE #{filter}" end

		db.execute query
	end

	private def set(attr, filter="")
		if self.get(attr, filter).length > 0 then
			query = "UPDATE #{attr} SET var = ?, var2 = ?"
		else

		end
	end
end


class User < TableModel
end
