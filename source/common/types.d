module common.types;

import http.request;
import http.response;

/// (carter):
/// Cheeky, but will be changed to a bespoke type similar to `QueryDict`.
alias Headers = string[string];
alias Cookies = string[string];
alias RequestHandler = HttpResponse function(HttpRequest request);

string toString(Headers headers) {
    string result = "";
    foreach (key, value; headers) {
        result ~= key ~ ": " ~ value ~ "\r\n";
    }
    return result;
}

enum Encoding {
    NONE
}