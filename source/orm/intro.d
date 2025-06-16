module orm.intro;

import std.meta;
import std.traits;
import std.string : toLower;

struct FieldInfo {
    string name;
    string nativeType;
    string sqlType;
}

template ModelInfo(T) {
    enum tableName = toLower(T.stringof);

    static FieldInfo[] getFields() {
        FieldInfo[] fields;

        static foreach (name; __traits(allMembers, T)) {
            static if (name[0] != '_' && name != "objects" && name != "save" && name != "ID") {
                static if (is(typeof(__traits(getMember, T, name)))) {
                    {
                        alias MemberType = typeof(__traits(getMember, T, name));
                        static if (__traits(compiles, mapToSqlType!MemberType)) {
                            string nativeTypeName = MemberType.stringof;
                            string sqlTypeName = mapToSqlType!MemberType;
                            fields ~= FieldInfo(name, nativeTypeName, sqlTypeName);
                        }
                    }
                }
            }
        }
        return fields;
    }

    template mapToSqlType(Type) {
        static if (is(Type == string))
            enum mapToSqlType = "TEXT";
        else static if (is(Type == int) || is(Type == long))
            enum mapToSqlType = "INTEGER";
        else static if (is(Type == float) || is(Type == double))
            enum mapToSqlType = "REAL";
        else static if (is(Type == bool))
            enum mapToSqlType = "INTEGER";
        else
            static assert(false, "Unsupported type: " ~ Type.stringof);
    }

    enum fields = getFields();
}