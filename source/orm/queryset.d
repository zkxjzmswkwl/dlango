module orm.queryset;

import std.array;
import std.algorithm;
import std.conv;
import std.exception : enforce;
import d2sqlite3;
import orm.intro : ModelInfo;
import orm.db : DbValue, hydrate, getDbConnection;
import std.sumtype;
import std.datetime;
import std.array : join;
import std.string;
import orm.q : Q;

mixin template ExceptionClass(string name) {
    mixin("class " ~ name ~ " : Exception {
        this(string msg) {
            super(msg);
        }
    }");
}

mixin ExceptionClass!"DoesNotExist";
mixin ExceptionClass!"MultipleResults";

struct QuerySet(T) {
    private DbValue[] _whereParams;
    private string[] _whereClauses;

    QuerySet!T filter(Q[] criteria) {
        auto newQs = this;
        foreach (crit; criteria) {
            string field;
            string op = "exact";
            if (crit.lookup.indexOf("__") != -1) {
                auto parts = crit.lookup.split("__");
                field = parts.front;
                op = parts.back;
            } else {
                field = crit.lookup;
            }

            string clause;
            DbValue param = crit.value;

            final switch (op) {
                case "exact":
                    clause = field ~ " = ?";
                    break;
                case "iexact":
                    clause = field ~ " = ?";
                    param = toLower(param.toString());
                    break;
                case "contains":
                    clause = field ~ " LIKE ?";
                    param = "%" ~ param.toString() ~ "%";
                    break;
                case "gt":
                    clause = field ~ " > ?";
                    break;
                case "gte":
                    clause = field ~ " >= ?";
                    break;
                case "lt":
                    clause = field ~ " < ?";
                    break;
                case "lte":
                    clause = field ~ " <= ?";
                    break;
                case "startswith":
                    clause = field ~ " LIKE ?";
                    param = param.toString() ~ "%";
                    break;
                case "endswith":
                    clause = field ~ " LIKE ?";
                    param = "%" ~ param.toString();
                    break;
                case "in":
                    clause = field ~ " IN ?";
                    break;
                case "isnull":
                    clause = field ~ " IS NULL";
                    break;
            }
            newQs._whereClauses ~= clause;
            newQs._whereParams ~= param;
        }
        return newQs;
    }

    QuerySet!T filter(Args...)(string clause, Args params) {
        auto newQs = this;
        newQs._whereClauses ~= clause;
        foreach(p; params) {
            newQs._whereParams ~= DbValue(p);
        }
        return newQs;
    }

    /// Example usage:
    /// User user = User.objects.get("username = ?", "carter");
    /// User user = User.objects.get("username = ? AND password = ?", "carter", "password");
    /// User user = User.objects.get("username = ? AND password = ?", ["carter", "password"]);
    /// User user = User.objects.get("username = ? AND password = ?", ["carter", "password"]);
    T get(Args...)(string clause, Args params) {
        auto finalQs = this;
        finalQs._whereClauses ~= clause;
        foreach(p; params) {
            finalQs._whereParams ~= DbValue(p);
        }
        auto results = finalQs.exec();
        enforce(results.length > 0, new DoesNotExist(T.stringof ~ " matching query does not exist."));
        enforce(results.length == 1, new MultipleResults("Query returned more than one " ~ T.stringof));
        return results[0];
    }

    int opApply(int delegate(ref T) dg) {
        auto results = this.exec();
        foreach(ref item; results) {
            if (dg(item)) return 1;
        }
        return 0;
    }

    private T[] exec() {
        string sql = "SELECT * FROM " ~ ModelInfo!T.tableName;
        if (_whereClauses.length > 0) {
            sql ~= " WHERE " ~ _whereClauses.join(" AND ");
        }
        sql ~= ";";

        auto db = getDbConnection();
        auto stmt = db.prepare(sql);

        foreach(i, param; _whereParams) {
            param.match!(
                (long l) => stmt.bind(cast(int)(i + 1), l),
                (string s) => stmt.bind(cast(int)(i + 1), s),
                (double d) => stmt.bind(cast(int)(i + 1), d),
                (Date d) => stmt.bind(cast(int)(i + 1), d),
            );
        }
        return hydrate!T(stmt.execute()); 
    }
}