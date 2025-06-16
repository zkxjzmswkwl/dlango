module orm.migration;

import d2sqlite3;
import orm.db;

abstract class Migration {
    void up(DbConnection db);
    void down(DbConnection db);
}