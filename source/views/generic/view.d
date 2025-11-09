module views.generic.view;

import http.request;
import views.generic.errors;
import std.stdio;

class View {
    private string path;
    private HttpRequest.Method[] allowedMethods;

    this(string path, HttpRequest.Method[] allowedMethods) {
        this.path = path;
        this.allowedMethods = allowedMethods;

        if (allowedMethods.length == 0) {
            writeln(ViewErrors.NO_ALLOWED_METHODS, path);
        }
    }
    // void dispatch()
}