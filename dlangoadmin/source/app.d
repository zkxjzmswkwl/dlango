import std.stdio;
import std.getopt;
import tool.migrate;
import tool.makemigrations;
import tool.createproject;

void main(string[] args) {
	if (args.length < 2) {
		writeln("Usage: dlango-admin <command> [options]");
		writeln("Available commands:");
		writeln("  makemigrations [--name=<name>] - Creates new migration(s) based on model changes.");
		writeln("  migrate                     - Applies database migrations.");
		writeln("  createproject [--name=<name>] - Creates a new Dlango project.");
		return;
	}

	string command = args[1];
	auto commandArgs = args[1 .. $];

	switch (command) {
		case "migrate":
			migrate();
			break;

		case "makemigrations":
			string migrationName;
			auto helpInfo = getopt(commandArgs, "name", &migrationName);

			if (helpInfo.helpWanted) {
				defaultGetoptPrinter("Options for makemigrations:", helpInfo.options);
				return;
			}
			makeMigrationsEntry(migrationName);
			break;
		
		case "createproject":
			string projectName;
			auto helpInfo = getopt(commandArgs, "name", &projectName);

			if (helpInfo.helpWanted) {
				defaultGetoptPrinter("Options for createproject:", helpInfo.options);
				return;
			}
			createProject(projectName);
			break;

		case "help":
		default:
			writeln("Unknown command: '", command, "'");
			writeln("Run 'dlango-admin' for a list of commands.");
			break;
	}
}
