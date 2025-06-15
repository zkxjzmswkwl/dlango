module migrations.d0001Initial;

import orm.migration;

class Migration_d0001 : Migration {
    override void up(DbConnection db) {
        db.execute(`CREATE TABLE user (id INTEGER PRIMARY KEY AUTOINCREMENT,  username TEXT NOT NULL,  emal TEXT NOT NULL,  age INTEGER NOT NULL)`);
        db.execute(`CREATE TABLE song (id INTEGER PRIMARY KEY AUTOINCREMENT,  year INTEGER NOT NULL,  genre TEXT NOT NULL,  title TEXT NOT NULL,  artist TEXT NOT NULL,  duration INTEGER NOT NULL,  album TEXT NOT NULL,  description TEXT NOT NULL,  path TEXT NOT NULL)`);
    }

    override void down(DbConnection db) {
        /// (carter): currently don't give a shit.
    }
}
