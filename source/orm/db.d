module orm.db;

import d2sqlite3;
import std.datetime;
import std.sumtype;

alias DbValue = SumType!(long, string, double, bool, Date, typeof(null));
alias DbRow = DbValue[string];
alias DbConnection = Database;

class GDatabase {
    private static Database _db;
    private static GDatabase _instance;
    private this(){
        _db = Database("test.db");
    }
    static GDatabase getInstance() {
        if (_instance is null) {
            _instance = new GDatabase();
        }
        return _instance;
    }

    public Database db() @property {
        return _db;
    }
}

DbConnection getDbConnection() { 
    return GDatabase.getInstance().db;
}

T[] hydrate(T)(ResultRange rows) {
    T[] results;
    if (rows.empty) {
        return results;
    }

    auto colCount = rows.columnCount;

    foreach(row; rows) {
        T item;
        foreach(i; 0 .. colCount) {
            auto colName = row.columnName(i);
            setField(item, colName, row[i]);
        }
        __traits(getMember, item, "_isNew") = false;
        results ~= item;
    }
    return results;
}

private void setField(T)(ref T item, string colName, ColumnData val) {
    final switch(colName) {
        static foreach(member; __traits(allMembers, T)) {
            /// (carter): this is rlly fkn hacky. Need fix.
            static if (member[0] != '_' && member != "objects" && member != "save" && member != "ID") {
                case member:
                    alias MemberType = typeof(__traits(getMember, T.init, member));
                    __traits(getMember, item, member) = val.as!MemberType;
                    return;
            }
        }
    }
}