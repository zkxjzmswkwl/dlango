module migrations.d0001Initial;

import orm.migration;

import orm.db;

class Migration_d0001 : Migration {
    override void up(DbConnection db) {
        db.execute(`CREATE TABLE user ( email TEXT NOT NULL,  username TEXT NOT NULL,  password TEXT NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  createdAt INTEGER NOT NULL)`);
        db.execute(`CREATE TABLE game ( description TEXT NOT NULL,  category TEXT NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  price TEXT NOT NULL,  name TEXT NOT NULL)`);
        db.execute(`CREATE TABLE product ( description TEXT NOT NULL,  category TEXT NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  price TEXT NOT NULL,  name TEXT NOT NULL)`);
        db.execute(`CREATE TABLE song ( year INTEGER NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  genre TEXT NOT NULL,  title TEXT NOT NULL,  artist TEXT NOT NULL,  duration INTEGER NOT NULL,  album TEXT NOT NULL,  description TEXT NOT NULL,  path TEXT NOT NULL)`);
    }

    override void down(DbConnection db) {
        /// (carter): currently don't give a shit.
    }
}
