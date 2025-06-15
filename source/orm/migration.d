module orm.migration;

import d2sqlite3;

interface DbConnection {
    ResultRange execute(string sql);
}

abstract class Migration {
    void up(DbConnection db);
    void down(DbConnection db);
}