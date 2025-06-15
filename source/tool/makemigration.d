module tool.makemigration;

import std.stdio;
import std.file;
import std.array;
import orm.schema;
import orm.models;
import orm.intro;
import std.sumtype;
import std.algorithm;
import std.format;
import std.conv;
import std.variant;
import asdf;

alias SchemaChange = Algebraic!(CreateTable, AddColumn);
struct CreateTable {
    string tableName;
    ModelSchema modelSchema;
}
struct AddColumn {
    string tableName;
    string columnName;
    FieldSchema schema;
}

void makeMigrationsEntry() {
    ProjectSchema currentState;
    ModelSchema modelSchema;
    static foreach (T; AllModels) {
        modelSchema = ModelSchema.init;
        foreach (field; ModelInfo!T.fields) {
            modelSchema.fields[field.name] = FieldSchema(field.nativeType, field.sqlType);
        }
        currentState[ModelInfo!T.tableName] = modelSchema;
    }
    currentState.toJSON.writeln;

    // load snapshot
    ProjectSchema snapshotState;
    string snapshotPath = ".orm_snapshot.json";
    if (exists(snapshotPath)) {
        snapshotState = readText(snapshotPath).deserialize!ProjectSchema;
    } else {
        writeln("No snapshot found, Initial migration.");
    }

    // diff
    SchemaChange[] changes;
    foreach (tableName, modelSchema; currentState.models) {
        auto snapshotModel = tableName in snapshotState.models;
        if (!snapshotModel) {
            changes ~= SchemaChange(CreateTable(tableName, modelSchema));
            continue;
        }
        foreach (fieldName, fieldSchema; modelSchema.fields) {
            if (fieldName !in snapshotModel.fields) {
                changes ~= SchemaChange(AddColumn(tableName, fieldName, fieldSchema));
            }
            /// (carter): changed fields?
        }
    }
    /// (carter): table removed? columns removed? etc.

    if (changes.length == 0) {
        writeln("No changes.");
        return;
    }

    // gen
    auto migrationDir = "source/migrations";
    if (!exists(migrationDir)) {
        mkdir(migrationDir);
    }

    // gen migration file
    long lastMigrationNum = 0;
    foreach (entry; dirEntries(migrationDir, SpanMode.shallow)) {
        if (!entry.name.endsWith(".d")) {
            continue;
        }
        /// (carter): This won't work on anything except x64 windows for now.
        version (Win64) {
            /// (carter): split by \ because windows.
            import std.array;
            writeln(entry.name);
            lastMigrationNum = max(lastMigrationNum, to!long(entry.name.split('\\')[$-1][0..4]));
        }
    }
    string newNum = format("d%04d", lastMigrationNum + 1);
    string desc = "Initial";
    string migrationName = newNum ~ desc ~ ".d";
    string migrationPath = migrationDir ~ "/" ~ migrationName;
    import std.array : appender;
    import std.format : formattedWrite;
    auto code = appender!string;

    formattedWrite(code, "module migrations.%s;\n\n", migrationName[0..$-2]);
    formattedWrite(code, "import orm.migration;\n\n");
    formattedWrite(code, "class Migration_%s : Migration {\n", newNum);
    formattedWrite(code, "    override void up(DbConnection db) {\n");
    foreach(change; changes) {
        writeln(change);
        change.visit!(
            (CreateTable ct) => formattedWrite(code,
                "        db.execute(`CREATE TABLE %s (id INTEGER PRIMARY KEY AUTOINCREMENT, %s)`);\n",
                ct.tableName,
                ct.modelSchema.fields.byKeyValue.map!(
                    kv => format(" %s %s NOT NULL", kv.key, kv.value.sqlType)
                ).join(", ")
            ),
            (AddColumn ac) => formattedWrite(code,
                "        db.execute(`ALTER TABLE %s ADD COLUMN %s %s NOT NULL`);\n",
                ac.tableName, ac.columnName, ac.schema.sqlType)
        );
    }
    formattedWrite(code, "    }\n\n");
    formattedWrite(code, "    override void down(DbConnection db) {\n");
    formattedWrite(code, "        /// (carter): currently don't give a shit.\n");
    formattedWrite(code, "    }\n");
    formattedWrite(code, "}\n");

    std.file.write(migrationPath, code.data);
    writeln("Generated migration: ", migrationPath);

    auto manifestPath = "source/migrations/manifest";
    if (!exists(manifestPath)) {
        auto manifestFile = File(manifestPath, "w");
        manifestFile.writeln(migrationName[0..$-2]);
        manifestFile.close();
    } else {
        auto manifestFile = File(manifestPath, "a");
        manifestFile.writeln(migrationName[0..$-2]);
        manifestFile.close();
    }
    writeln("Updated manifest file.");
}