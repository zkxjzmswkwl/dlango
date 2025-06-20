module templates.index;

import std.string : format;

string render(string name) {
    return format(`Hello, %s!`,
        name);
}
