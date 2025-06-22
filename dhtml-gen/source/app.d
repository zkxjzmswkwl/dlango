module app;

import std.file;
import std.path;
import std.stdio;
import std.array;
import std.format;
import std.exception;
import std.algorithm;
import lexer;
import parser;
import generator;


void main(string[] args) {
    if (args.length != 2) {
        stderr.writeln("Usage: dtml-gen <path/to/templates_directory>");
        return;
    }
    
    auto rootDir = args[1];
    enforce(exists(rootDir) && isDir(rootDir),
        "dir not found at '" ~ rootDir ~ "'");

    writeln("Scanning: ", rootDir);
    
    foreach (entry; dirEntries(rootDir, SpanMode.depth)) {
        if (entry.isFile && entry.name.endsWith(".dtml")) {
            compileTemplate(entry.name);
        }
    }
    
    writeln("job done");
}

void compileTemplate(string inputPath) {
    try {
        writeln("Transpiling: ", inputPath);
        string templateContent = readText(inputPath);
        auto lexer = new Lexer(templateContent);
        auto tokens = lexer.tokenize();

        auto parser = new Parser(tokens);
        auto ast = parser.parse();

        auto generator = new Generator(ast);

        string outputPath = setExtension(inputPath, "d");
        string modulePath = outputPath.replace("source" ~ dirSeparator, "")
                                      .replace(dirSeparator, ".")
                                      .replace("../", "")
                                      .replace("..", "")
                                      .replace(".d", "");
        writeln("modulePath: ", modulePath);

        string generatedCode = generator.generate(modulePath);
        std.file.write(outputPath, generatedCode);
        
    } catch (Exception e) {
        stderr.writeln("    ERROR: Failed to transpile", inputPath);
        stderr.writeln("     -> ", e.msg);
    }
}
