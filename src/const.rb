BAD_REP		= -1
NEUTRAL_REP	= 0
GOOD_REP 	= 1

MIN_REP		= -100
MAX_REP 	= 100

PERM_LEVELS = {
	banned: 2**0, # denies the user everything
	admin: 2**1, # admin role (gives all flags except "banned")
	roleman: 2**2, # allows the user to manage roles
	cateman: 2**3, # allows the user to manage categories
	rmpost: 2**4, # allows the user to remove other peoples auctions
	moneyman: 2**5 # allows the user to give/take money from people
}

# Constant roles that will always exist
# IMPORTANT!: these ids are allocated for the specified roles. It is imperative that other roles have these ids!
ROLES = {
	admin: {
		id: 1, 		
		name: "Admin",
		color: "#4776C1",
		flags: PERM_LEVELS[:admin]
	},

	banned: {
		id: 2,
		name: "Banned",
		color: "#de2a1d",
		flags: PERM_LEVELS[:banned]
	}
}

ROLE_IDS = [] 
ROLES.each {|_, role| ROLE_IDS << role[:id]}

# DB stuff
DB_PATH = "db/main.db"

# Auction constants
MIN_INIT_PRICE = 1
MAX_INIT_PRICE = 1e9

MIN_TITLE_LEN = 2
MAX_TITLE_LEN = 32

MIN_DESC_LEN = 0
MAX_DESC_LEN = 512

MIN_DELTA_TIME = 3600 # 1 hour

# User constants
AVATAR_SIZE = 1024 # width & height

MIN_PASSWORD_LEN = 8
MIN_NAME_LEN = 2
MAX_NAME_LEN = 28 

MIN_BIO_LEN = 0
MAX_BIO_LEN = 128

MIN_MSG_LEN = 0
MAX_MSG_LEN = 128

EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/
NAME_REGEX_STR = "[a-zA-Z-_0-9 ]{#{MIN_NAME_LEN},#{MAX_NAME_LEN}}"
BIO_REGEX_STR = "{#{MIN_BIO_LEN},#{MAX_BIO_LEN}}"
DESC_REGEX_STR = "{#{MIN_DESC_LEN},#{MAX_DESC_LEN}}"
TITLE_REGEX_STR = "{#{MIN_TITLE_LEN},#{MAX_TITLE_LEN}}"
MSG_REGEX_STR = "{#{MIN_MSG_LEN},#{MAX_MSG_LEN}}"

TIME_FORMATS = {
	w: 604800,
	d: 86400,
	h: 3600,
	m: 60,
	s: 1
}


# Routes that needs auth
AUTH_ROUTES = %w[/settings /auction /user /admin]

