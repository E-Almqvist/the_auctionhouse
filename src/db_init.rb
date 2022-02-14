require_relative "db_models.rb"

LOAD_MODELS = [
	User
]

def db_init
	LOAD_MODELS.each do |model|
		model.init_table # init all tables
	end
end
