module http.request;

import common.types;
import std.conv : to;
import std.format;

class HttpRequest {
    private Encoding encoding;
    private Headers _headers;
    private Cookies _cookies;
    enum Method {
        GET,
        POST,
        PUT,
        DELETE,
        PATCH,
        OPTIONS,
        HEAD,
        TRACE
    }
    private Method method;
    private string path;
    private string httpVersion;
    // temporary
    private ubyte[] body;

    /// (carter):
    /// These will change to be a handrolled type that supports generics.
    /// Typecasting of inserted types will be done at runtime unless otherwise specified by usercode.
    private string[string] postData;
    private string[string] getData;

    this(Method method, string path, string httpVersion, ubyte[] body) {
        this.method = method;
        this.path = path;
        this.httpVersion = httpVersion;
        this.body = body;
    }

    /// (carter):
    /// Memcaching these properties is a future win.
    /// In a sense, not doing it now sets me up for success later. If you think about it.
    @property
    Headers headers() { return this._headers; }

    @property
    Cookies cookies() { return this._cookies; }

    @property
    string[string] form() { return this.postData; }

    @property
    string[string] urlQuery() { return this.getData; }

    override string toString() {
        return "HttpRequest(method: %s, path: %s, httpVersion: %s, body: %s)".format(this.method,
                                                                                     this.path,
                                                                                     this.httpVersion,
                                                                                     this.body.to!string);
    }
}