import std.stdio;
import std.file;
import http.server;
import http.request;
import http.response;
import common.types;
import orm.models;
import orm.manager;
import std.traits;
import testsql;
import orm.state.snapshot;
import orm.schema;
import tool.makemigration;
import tool.migrate;


string getIndexHTML() {
	return readText("test/index.html");
}

void run() {
	RequestHandler[string] routes;
	routes["/"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), getIndexHTML());
	};
	routes["/hello"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), "HELLO BROTHERMAN!");
	};
	HttpServer server = new HttpServer(routes);
}

void main(string[] args) {
	import std.conv : to;
	if (args.length == 2 && args[1] == "makemigrations")
		makeMigrationsEntry();
	else if (args.length == 2 && args[1] == "migrate") {
		migrate();
	} else {
		run();
	}
}
