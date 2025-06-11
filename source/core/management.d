module core.management;

/// (carter):
/// Placeholder. Will need to read a reflection refresher.
string[string] getCommands() {
    return ["not": "implemented"];
}

/// (carter):
/// Placeholder. Will mimic Django's CLI command feature.
/// (basically stored procedures at the application level)
class Management {
    string[string] commands;

    this() {
        this.commands = getCommands();
    }
}