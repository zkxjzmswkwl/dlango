module views.generic.view;

import std.logger;
import http.request;
import views.generic.errors;

class View {
    private string path;
    private HttpRequest.Method[] allowedMethods;

    this(string path, HttpRequest.Method[] allowedMethods) {
        this.path = path;
        this.allowedMethods = allowedMethods;

        if (allowedMethods.length == 0) {
            warning(ViewErrors.NO_ALLOWED_METHODS, path);
        }
    }
    // void dispatch()
}