require_relative "db_models.rb"

LOAD_MODELS = [
	User,
	Role,
	User_Role_relation,
	Auction,
	Auction_Category_relation,
	Category,
	Image
]

def db_init
	LOAD_MODELS.each do |model|
		model.init_table # init all tables
	end
end
