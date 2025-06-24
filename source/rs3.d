import std.stdio;
import std.file;
import std.json;
import std.conv;
import std.array;
import orm.models;

// test shit

void testrs3() {
    string jsonText = readText(".vscode/money_methods.json");
    JSONValue parsed = parseJSON(jsonText);

    foreach (entry; parsed.array) {
        MoneyMethod(
            entry["title"].get!string,
            entry["category"].get!string,
            entry["intensity"].get!string,
            entry["profit"].get!long
        ).save();
    }
}