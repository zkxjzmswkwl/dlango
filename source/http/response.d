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

const HttpStatus OK = HttpStatus(200, "OK");
const HttpStatus BAD_REQUEST = HttpStatus(400, "Bad Request");
const HttpStatus NOT_FOUND = HttpStatus(404, "Not Found");
const HttpStatus INTERNAL_SERVER_ERROR = HttpStatus(500, "Internal Server Error");
const HttpStatus NOT_IMPLEMENTED = HttpStatus(501, "Not Implemented");
const HttpStatus BAD_GATEWAY = HttpStatus(502, "Bad Gateway");
const HttpStatus SERVICE_UNAVAILABLE = HttpStatus(503, "Service Unavailable");

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