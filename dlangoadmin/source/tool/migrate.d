module tool.migrate;

import std.stdio;
import std.file;
import std.path;
import std.process;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import asdf;
import std.json;
import std.format : formattedWrite;

string generateRunnerSource(string projectRoot) {
	auto migrationsDir = buildPath(projectRoot, "source", "migrations");
	auto manifestPath = buildPath(migrationsDir, "manifest");

	if (!exists(manifestPath)) {
		stderr.writeln("Error: '", manifestPath, "' not found.");
		stderr.writeln("Hint: Have you created any migrations yet? Try running 'dlango-admin makemigrations'.");
		return null;
	}

	auto manifestContent = readText(manifestPath);
	auto migrationNames = manifestContent.splitLines().filter!(a => a.length > 0).array;

	auto code = appender!string();
	code.put("module _runner;\n\n");

	foreach (name; migrationNames) {
		formattedWrite(code, "import migrations.%s;\n", name);
	}

	code.put("\n");
	code.put("import orm.db;\n");
	code.put("import std.stdio;\n\n");
	code.put("void runMigrationByName(string name, DbConnection db) {\n");
	code.put("    writeln(\"Executing migration: \", name);\n");
	code.put("    final switch(name) {\n");

	foreach (name; migrationNames) {
		string classNum = name.split('_')[0];
		formattedWrite(code, "        case \"%s\":\n", name);
		formattedWrite(code, "            auto m = new Migration_%s();\n", classNum);
		formattedWrite(code, "            m.up(db);\n");
		formattedWrite(code, "            return;\n");
	}

	code.put("    }\n");
	code.put("}\n");

	return code.data;
}

enum MIGRATION_MAIN_TEMPLATE = q{
import _runner;
import orm.db;
import orm.migration;
import orm.queryset;
import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.stdio;
import d2sqlite3;
import settings.db;

void main() {
	auto db_ptr = settings.db.getDbConnection();

	db_ptr.execute(`
		CREATE TABLE IF NOT EXISTS dlango_migrations (
			id INTEGER PRIMARY KEY,
			name TEXT NOT NULL UNIQUE,
			applied_at TEXT NOT NULL
		);
	`);

	bool[string] prevMigrations;
	try {
		ResultRange results = db_ptr.execute("SELECT name FROM dlango_migrations");
		foreach (Row row; results) {
			prevMigrations[row["name"].as!string] = true;
		}
	}
	catch (Exception e) {
		writeln("Could not query migrations table, assuming it's empty. Error: ", e.msg);
	}

	string[] pendingMigrations;
	foreach (entry; dirEntries("source/migrations", SpanMode.shallow)) {
		if (entry.name.endsWith(".d") && entry.name.canFind("_")) {
			auto migrationName = stripExtension(baseName(entry.name));
			if (migrationName != "__package") {
				pendingMigrations ~= migrationName;
			}
		}
	}
	sort(pendingMigrations);

	writeln("Found migrations: ", pendingMigrations);
	uint appliedCount = 0;
	foreach (name; pendingMigrations) {
		if (name in prevMigrations) {
			continue;
		}

		writeln("Applying migration: ", name);
		runMigrationByName(name, *db_ptr);
		db_ptr.execute("INSERT INTO dlango_migrations (name, applied_at) VALUES (?, datetime('now'))", name);
		appliedCount++;
	}

	if (appliedCount == 0) {
		writeln("All migrations are up to date.");
	} else {
		writeln("Applied ", appliedCount, " new migration(s).");
	}
}
};


void migrate() {
	writeln("Running migrate command...");
	auto projectRoot = getcwd();

    string dlangoPath = "/Users/cartersmith/personal/dlango";
    writeln("Using dlango framework from: ", dlangoPath);

	auto tmpDir = buildPath(projectRoot, ".dlango_tmp");
	scope (exit) {
		if (exists(tmpDir)) {
			rmdirRecurse(tmpDir);
		}
	}
	mkdirRecurse(tmpDir);
    mkdir(buildPath(tmpDir, "source"));

	auto runnerSource = generateRunnerSource(projectRoot);
	if (runnerSource is null) {
		return;
	}
	std.file.write(buildPath(tmpDir, "source", "_runner.d"), runnerSource);
	std.file.write(buildPath(tmpDir, "source", "app.d"), MIGRATION_MAIN_TEMPLATE);

    auto recipePath = buildPath(tmpDir, "dub.sdl");
    auto recipeContent = appender!string();
    formattedWrite(recipeContent, `name "_internal_runner"
targetType "executable"
mainSourceFile "source/app.d"
dependency "dlango" path="%s"
dependency "asdf" version="~>0.7.17"
dependency "d2sqlite3" repository="git+https://github.com/zkxjzmswkwl/d2sqlite3.git" version="~v1.x.x"
sourcePaths "source" "../source"
excludedSourceFiles "../source/app.d"
`, dlangoPath);
    
    std.file.write(recipePath, recipeContent.data);

	writeln("Compiling migration executor...");
    
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

	if (buildResult.status != 0) {
		stderr.writeln("\n--- Migration Error ---");
		stderr.writeln("The migration executor failed to compile.");
		stderr.writeln("Compiler Output:");
		stderr.write(buildResult.output);
        return;
	}

    writeln("Applying migrations...");
    auto executablePath = buildPath(tmpDir, "_internal_runner");
    string[] runArgs = [ executablePath ];

    auto runResult = execute(runArgs);

	if (runResult.status != 0) {
		stderr.writeln("\n--- Migration Error ---");
		stderr.writeln("The process failed to run.");
		stderr.writeln("Runtime Output:");
		stderr.write(runResult.output);
	} else {
		writeln("\n--- Migration Output ---");
		stdout.write(runResult.output);
		writeln("------------------------");
	}
}
