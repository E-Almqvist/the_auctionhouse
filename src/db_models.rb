class TableModel  # Base model
	attr_reader :table_name
	def initialize(table_name)
		@table_name = table_name
	end

	private def get(entity, filter="")
		db = db_handle # get the db handle
		query = "SELECT #{entity} FROM #{@table_name} " # create the query string
		if filter != "" then query += "WHERE #{filter}" end

		db.execute query
	end
end


class User < TableModel
end
