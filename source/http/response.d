module http.response;

import std.conv : to;
import common.types;

struct HttpStatus {
    int code;
    string message;

    string toString() {
        return code.to!string() ~ " " ~ message;
    }
}

class HttpResponse {
    private HttpStatus status;
    private Headers headers;
    private string body;

    this(HttpStatus status, Headers headers, string body) {
        this.status = status;
        this.headers = headers;
        this.body = body;
    }

    public string serialize() {
        return "HTTP/1.1 " ~ status.toString() ~ "\r\n" ~ headers.toString() ~ "\r\n" ~ body;
    }
}