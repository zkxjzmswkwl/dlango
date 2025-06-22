module templates.test;

import std.array : appender;
import std.conv : to;

string UserProfilePage(app.user.models.User user, string page_title)
{
    auto result = appender!string;

    result.put(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>`);
    result.put(to!string(page_title));
    result.put(`</title>
    </head>
    <body>
        <h1>`);
    result.put(to!string(user.username));
    result.put(`</h1>
        <p>Email: `);
    result.put(to!string(user.email));
    result.put(`</p>

        `);
    if (user.age > 30)
    {
        result.put(`
            <p>Dies soon.</p>
        `);
    }
    result.put(`
    </body>
    </html>
`);

    return result.data;
}
