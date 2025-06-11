module views.generic.view;

import std.logger;
import http.request;

class View {
    private string path;
    private HttpRequest.Method[] allowedMethods;

    this(string path, HttpRequest.Method[] allowedMethods) {
        this.path = path;
        this.allowedMethods = allowedMethods;

        if (allowedMethods.length == 0) {
            warning("No allowed methods provided for view at path: %s, as such no requests will be allowed.", path);
        }
    }

    // void dispatch()
}