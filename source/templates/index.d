module templates.index;

import orm.models;
import std.array : appender;
import std.conv : to;
import templates.navbar;

string Index(string title, MoneyMethod[] methods) {
    auto result = appender!string;

    result.put(`<html>
        <head>
             <title>`);
    result.put(to!string(title));
    result.put(`</title>
            <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
        </head>
        <body class="bg-gray-700">`);
    result.put(Navbar());
    result.put(`<div class="container bg-gray-500 p-4 border-2 border-gray-700 w-1/2 mx-auto text-white">`);
    foreach (method; methods) {
    result.put(`<div class="border-2 border-gray-700 p-4 mb-2">
                        <h1>`);
    result.put(to!string(method.title));
    result.put(`</h1>
                        <p>`);
    result.put(to!string(method.category));
    result.put(`</p>
                        <p>`);
    result.put(to!string(method.intensity));
    result.put(`</p>
                        <p>`);
    result.put(to!string(method.profit));
    result.put(`</p>
                    </div>`);
    }
    result.put(`</div>
        </body>
    </html>`);

    return result.data;
}
