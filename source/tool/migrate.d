module tool.migrate;

import d2sqlite3;
import std.array;
import std.range;
import std.conv;
import std.file;
import std.stdio;
import std.algorithm;
import std.path;
import orm.db;
import orm.migration;
import orm.queryset;
import orm.db : getDbConnection;

string generateMigrationRunner() {
    import std.array : appender;
    import std.format : formattedWrite;

    /// (carter): requires program to be compiled with -J flag.
    enum manifestContent = import("source/migrations/manifest");
    enum migrationNames = manifestContent.to!string.split("\r\n");

    auto code = appender!string;

    foreach(name; migrationNames) {
        if (name.to!string.length == 0) continue;
        formattedWrite(code, " import migrations.%s;\r\n", name);
    }

    formattedWrite(code, "import std.stdio;\n");
    formattedWrite(code, "void runMigrationByName(string name, DbConnection db) {\n");
    formattedWrite(code, "writeln(\"Running migration: \" ~ name);\n");
    formattedWrite(code, "    final switch(name) {\n");
    foreach(name; migrationNames) {
        if (name.to!string.length == 0) continue;
        string classNum = name.to!string[0..5].replace("\r", "").replace("\n", "");
        formattedWrite(code, "        case \"%s\":\n", name);
        formattedWrite(code, "            auto m = new Migration_%s();\n", classNum);
        formattedWrite(code, "            m.up(db);\n");
        formattedWrite(code, "            return;\n");
    }
    /// (carter): default not allowed in final? TODO: workshop it
    // formattedWrite(code, "        default: assert(0, \"? migration: \" ~ name);\n");
    formattedWrite(code, "    }\n");
    formattedWrite(code, "}\n");

    return code.data;
}

pragma(msg, generateMigrationRunner());
mixin(generateMigrationRunner());

void migrate() {
    auto db = getDbConnection();

    db.execute(`
        CREATE TABLE IF NOT EXISTS dlango_migrations (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            applied_at TEXT NOT NULL
        );
    `);

    bool[string] prevMigrations;
    ResultRange results = db.execute("SELECT name FROM dlango_migrations");
    foreach (Row row; results) {
        auto name = row["name"].as!string;
        prevMigrations[name] = true;
    }

    string[] pendingMigrations;
    foreach (entry; dirEntries("source/migrations", SpanMode.shallow)) {
        if (entry.name.endsWith(".d")) {
            auto migrationName = entry.name.replace("\\", "/");
            migrationName = stripExtension(entry.name.split("/")[$-1]);
            writeln(migrationName);
            pendingMigrations ~= migrationName;
        }
    }
    sort(pendingMigrations);

    writeln("Pending migrations: ", pendingMigrations);
    foreach (name; pendingMigrations) {
        if (name in prevMigrations) continue;

        writeln("Applying migration: ", name);
        name = name.replace("\\", "/").split("/")[$-1];
        runMigrationByName(name, db);
        db.execute(`
            INSERT INTO dlango_migrations (name, applied_at) VALUES ('` ~ name ~ `', datetime('now'));
        `);

    }
}