module templates.index;

import orm.models;
import std.array : appender;
import std.conv : to;
import templates.navbar : Navbar;

string Index(string title, User[] alotofusers) {
    auto result = appender!string;

    result.put(`<html>
        <head>
             <title>`);
    result.put(to!string(title));
    result.put(`</title>
            <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
        </head>
        <body>`);
    result.put(Navbar());
    result.put(`<div class="container p-4 border-2 border-gray-300 w-1/2 mx-auto">`);
    foreach (user; alotofusers) {
    result.put(`<h1>`);
    result.put(to!string(user.ID));
    result.put(`:`);
    result.put(to!string(user.username));
    result.put(`</h1>`);
    }
    result.put(`</div>
        </body>
    </html>`);

    return result.data;
}
