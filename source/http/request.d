module http.request;

import common.types;
import std.conv : to;
import std.format;
import std.algorithm;
import std.array;

class HttpRequest {
    private Encoding encoding;
    private Headers _headers;
    private Cookies _cookies;
    private string _path;
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
    private Method _method;
    private string httpVersion;
    // temporary
    private ubyte[] body;

    /// (carter):
    /// These will change to be a handrolled type that supports generics.
    /// Typecasting of inserted types will be done at runtime unless otherwise specified by usercode.
    private string[string] postData;
    private string[string] getData;

    this(Method method, string path, string httpVersion, Headers headers) {
        this._method = method;
        this._path = path;
        this.httpVersion = httpVersion;
        this._headers = headers;
    }

    /// (carter):
    /// Memcaching these properties is a future win.
    /// In a sense, not doing it now sets me up for success later. If you think about it.
    @property
    Headers headers() { return this._headers; }

    @property
    Cookies cookies() { return this._cookies; }

    @property
    string path() { return this._path; }

    @property
    string[string] form() { return this.postData; }

    @property
    Method method() { return this._method; }

    @property
    string[string] urlQuery() {
        import std.string : indexOf;
        if (this.getData.empty) {
            string[string] params;
            auto qpos = this.path.indexOf('?');
            if (qpos == -1)
                return params;

            string query = this.path[qpos + 1 .. $];
            foreach (pair; query.split('&')) {
                if (pair.length == 0)
                    continue;

                auto kv = pair.split('=');
                string key = kv[0];
                string value = kv.length > 1 ? kv[1] : "";

                params[key] = value;
            }

            this.getData = params;
        }
        return this.getData;
    }

    override string toString() {
        return "HttpRequest(method: %s, path: %s, httpVersion: %s, body: %s)".format(this.method,
                                                                                     this.path,
                                                                                     this.httpVersion,
                                                                                     this._headers.toString());
    }
}