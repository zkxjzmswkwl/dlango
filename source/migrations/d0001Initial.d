module migrations.d0001Initial;

import orm.migration;

import orm.db;

class Migration_d0001 : Migration {
    override void up(DbConnection db) {
        db.execute(`CREATE TABLE user ( email TEXT NOT NULL,  username TEXT NOT NULL,  password TEXT NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  createdAt INTEGER NOT NULL)`);
        db.execute(`CREATE TABLE moneymethod ( intensity TEXT NOT NULL,  category TEXT NOT NULL,  id INTEGER NOT NULL PRIMARY KEY,  title TEXT NOT NULL,  profit INTEGER NOT NULL)`);
    }

    override void down(DbConnection db) {
        /// (carter): currently don't give a shit.
    }
}
