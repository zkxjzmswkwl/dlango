import std.stdio;
import std.file;
import http.server;
import http.request;
import http.response;
import common.types;
import orm.model;
import orm.manager;
import std.traits;
import testsql;

struct User {
	mixin Model;

	string username;
	string email;
	int age;

	static auto objects() { return Manager!User();}
}

string getIndexHTML() {
	return readText("test/index.html");
}

void main() {
	go();
	RequestHandler[string] routes;
	routes["/"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), getIndexHTML());
	};
	routes["/hello"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), "HELLO BROTHERMAN!");
	};
	HttpServer server = new HttpServer(routes);
}
