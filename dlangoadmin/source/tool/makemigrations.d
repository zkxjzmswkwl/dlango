module tool.makemigrations;

import std.stdio;
import std.file;
import std.path;
import std.process;
import std.string;
import std.format;
import std.array;
import asdf;
import std.json;

enum MAKEMIGRATIONS_MAIN_TEMPLATE = q{
/+ dub.sdl:
    dependency "dlango" path="../"
    dependency "asdf" version="~>0.7.17"
    dependency "d2sqlite3" repository="git+https://github.com/zkxjzmswkwl/d2sqlite3.git" version="~v1.x.x"
+/
import std.stdio;
import std.file;
import std.array;
import std.sumtype;
import std.algorithm;
import std.format;
import std.conv;
import std.variant;
import std.path;

// Framework imports
import orm.schema;
import orm.models;
import orm.intro;
import asdf; // General asdf import

// User project imports
import models; // Assumes user models are in a 'models' package
import settings.db; // To ensure settings are valid

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

void main(string[] args) {
    // These paths are relative to the user's project root, where this program is executed.
    string snapshotPath = ".orm_snapshot.json";
    auto projectRoot = ".";

    ProjectSchema currentState;
    ModelSchema modelSchema;

    // 1. Build the current schema state from the user's models
    //    Explicitly use `models.AllModels` to avoid symbol conflicts.
    static foreach (T; models.AllModels) {
        modelSchema = ModelSchema.init;
        foreach (field; ModelInfo!T.fields) {
            modelSchema.fields[field.name] = FieldSchema(field.nativeType, field.sqlType);
        }
        currentState.models[ModelInfo!T.tableName] = modelSchema;
    }

    // 2. Load the previous schema state from the snapshot file
    ProjectSchema snapshotState;
    if (exists(snapshotPath)) {
        try {
            snapshotState = readText(snapshotPath).deserialize!ProjectSchema;
        } catch (Exception e) {
            stderr.writeln("Warning: Could not deserialize snapshot file. It might be corrupt. Creating a new one.");
        }
    } else {
        writeln("No snapshot found, this will be the initial migration.");
    }

    // 3. Diff the current state against the snapshot
    SchemaChange[] changes;
    foreach (tableName, currentModel; currentState.models) {
        auto snapshotModel = tableName in snapshotState.models;
        if (!snapshotModel) {
            changes ~= SchemaChange(CreateTable(tableName, currentModel));
            continue;
        }
        foreach (fieldName, fieldSchema; currentModel.fields) {
            if (fieldName !in snapshotModel.fields) {
                changes ~= SchemaChange(AddColumn(tableName, fieldName, fieldSchema));
            }
            // TODO: Add detection for changed and removed fields
        }
    }
    // TODO: Add detection for removed tables

    if (changes.length == 0) {
        writeln("No changes detected.");
        return;
    }

    // 4. Generate the new migration file
    auto migrationDir = buildPath(projectRoot, "source", "migrations");
    mkdirRecurse(migrationDir);

    long lastMigrationNum = 0;
    foreach (entry; dirEntries(migrationDir, SpanMode.shallow)) {
        if (entry.name.endsWith(".d") && baseName(entry.name).canFind('_')) {
            try {
                auto numStr = baseName(entry.name).split('_')[0];
                if (numStr.startsWith("m")) {
                    numStr = numStr[1..$]; // remove the 'm' prefix before converting to long
                }
                lastMigrationNum = max(lastMigrationNum, to!long(numStr));
            } catch (Exception e) { /* Ignore files that don't match the format */ }
        }
    }

    // Prefix the migration number with 'm' to create a valid D identifier
    string newNum = format("m%04d", lastMigrationNum + 1);
    string desc = (args.length > 1 && args[1].length > 0) ? args[1].replace("_", "").replace(" ", "") : "auto";
    string migrationModuleName = newNum ~ "_" ~ desc;
    string migrationFileName = migrationModuleName ~ ".d";
    string migrationPath = buildPath(migrationDir, migrationFileName);

    auto code = appender!string();

    formattedWrite(code, "module migrations.%s;\n\n", migrationModuleName);
    formattedWrite(code, "import orm.migration;\n");
    formattedWrite(code, "import orm.db;\n\n");
    formattedWrite(code, "class Migration_%s : Migration {\n", newNum);
    formattedWrite(code, "    override void up(DbConnection db) {\n");

    foreach(change; changes) {
        change.visit!(
            (CreateTable ct) => formattedWrite(code,
                "        db.execute(`CREATE TABLE %s (%s)`);\n",
                ct.tableName,
                ct.modelSchema.fields.byKeyValue.map!(
                    kv => kv.key == "id" ?
                        format("%s %s PRIMARY KEY", kv.key, kv.value.sqlType) :
                        format("%s %s NOT NULL", kv.key, kv.value.sqlType)
                ).join(", ")
            ),
            (AddColumn ac) => formattedWrite(code,
                "        db.execute(`ALTER TABLE %s ADD COLUMN %s %s NOT NULL`);\n",
                ac.tableName, ac.columnName, ac.schema.sqlType)
        );
    }

    formattedWrite(code, "    }\n\n");
    formattedWrite(code, "    override void down(DbConnection db) {\n");
    formattedWrite(code, "        // TODO: Implement downgrade logic\n");
    formattedWrite(code, "    }\n");
    formattedWrite(code, "}\n");

    std.file.write(migrationPath, code.data);
    writeln("Generated migration: ", migrationPath);

    // 5. Update the manifest file
    auto manifestPath = buildPath(migrationDir, "manifest");
    auto manifestFile = File(manifestPath, "a"); // Append mode creates if not exists
    manifestFile.writeln(migrationModuleName);
    manifestFile.close();
    writeln("Updated manifest file.");

    // 6. Update the snapshot to the current state
    std.file.write(snapshotPath, currentState.toJSON().to!string);
    writeln("Updated schema snapshot.");
}
};

void makeMigrationsEntry(string name)
{
	writeln("Running makemigrations command...");
	auto projectRoot = getcwd();

    string dlangoPath = "/Users/cartersmith/personal/dlango";

	auto tmpDir = buildPath(projectRoot, ".dlango_tmp");
	scope (exit)
	{
		if (exists(tmpDir))
		{
			rmdirRecurse(tmpDir);
		}
	}
	mkdirRecurse(tmpDir);
    mkdir(buildPath(tmpDir, "source"));

	auto mainPath = buildPath(tmpDir, "source", "app.d");
	std.file.write(mainPath, MAKEMIGRATIONS_MAIN_TEMPLATE);

    auto recipePath = buildPath(tmpDir, "dub.sdl");
    auto recipeContent = appender!string();
    formattedWrite(recipeContent, `name "_internal_runner"
targetType "executable"
dependency "dlango" path="%s"
dependency "asdf" version="~>0.7.17"
dependency "d2sqlite3" repository="git+https://github.com/zkxjzmswkwl/d2sqlite3.git" version="~v1.x.x"
importPaths "source" "%s"
`, dlangoPath, buildPath(projectRoot, "source"));
    
    std.file.write(recipePath, recipeContent.data);

	writeln("Compiling migration generator...");
    
    import std.file : chdir;
    auto originalDir = getcwd();
    scope(exit) chdir(originalDir);
    chdir(tmpDir);

	string[] dubBuildArgs = [
        "dub",
		"build",
        "--quiet"
	];

	auto buildResult = execute(dubBuildArgs);
    chdir(originalDir);

	if (buildResult.status != 0)
	{
		stderr.writeln("\n--- Makemigrations Error ---");
		stderr.writeln("The migration generator failed to compile.");
		stderr.writeln("Compiler Output:");
		stderr.write(buildResult.output);
        return;
	}

    writeln("Introspecting models and generating migration...");
    auto executablePath = buildPath(tmpDir, "_internal_runner");
    string[] runArgs = [
        executablePath,
        name
    ];

    auto runResult = execute(runArgs);

	if (runResult.status != 0)
	{
		stderr.writeln("\n--- Makemigrations Error ---");
		stderr.writeln("The process failed to run.");
		stderr.writeln("Runtime Output:");
		stderr.write(runResult.output);
	}
	else
	{
		writeln("\n--- Makemigrations Output ---");
		stdout.write(runResult.output);
		writeln("-----------------------------");
	}
}
