import std.stdio;
import std.file;
import http.server;
import http.request;
import http.response;
import common.types;
import orm.models;
import tool.makemigration;
import tool.migrate;
import orm.q : Q;

string getIndexHTML() {
	return readText("test/index.html");
}

void testORM() {
	for (int i = 0; i < 10_000; i++) {
		User("retrac", "retrac@gmail.com", "password").save();
	}
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
	if (args.length == 2) {
		switch (args[1]) {
			case "makemigrations":
				makeMigrationsEntry();
				break;
			case "migrate":
				migrate();
				break;
			case "orm":
				testORM();
				break;
			default:
				run();
				break;
		}
	} else {
		run();
	}
}
