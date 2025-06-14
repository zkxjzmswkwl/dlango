import std.stdio;
import std.file;
import http.server;
import http.request;
import http.response;
import common.types;

string getIndexHTML() {
	return readText("test/index.html");
}

void main() {
	RequestHandler[string] routes;
	routes["/"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), getIndexHTML());
	};
	routes["/hello"] = (request) {
		return new HttpResponse(HttpStatus(200, "OK"), new Headers(), "HELLO BROTHERMAN!");
	};
	HttpServer server = new HttpServer(routes);
}
