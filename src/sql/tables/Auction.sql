CREATE TABLE IF NOT EXISTS "Auction" (
	"id"			INTEGER NOT NULL UNIQUE,
	"user_id"		INTEGER NOT NULL,
	"title"			TEXT NOT NULL,
	"description"	TEXT NOT NULL,
	"init_price"	INTEGER NOT NULL DEFAULT 1,
	"start_time"	DATE NOT NULL,
	"end_time"		DATE NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
