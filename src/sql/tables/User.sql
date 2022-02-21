CREATE TABLE IF NOT EXISTS "User" (
	"id"			INTEGER NOT NULL UNIQUE,
	"email"			TEXT NOT NULL UNIQUE,
	"pw_hash"		TEXT NOT NULL UNIQUE,
	"name"			TEXT NOT NULL DEFAULT 'Unknown',
	"bio_text"		TEXT NOT NULL DEFAULT 'No information given.',
	"balance"		REAL NOT NULL DEFAULT 0,
	"avatar_url"	TEXT NOT NULL DEFAULT '/avatars/default.png',
	"reputation"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id" AUTOINCREMENT)
);
