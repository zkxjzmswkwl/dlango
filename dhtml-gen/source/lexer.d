module lexer;

import std.string;
import std.conv;

enum TokenType {
    Text,
    VarStart,
    VarEnd,
    TagStart,
    TagEnd,
    Identifier,
    If,
    Else,
    EndIf,
    Expression,
    EOF
};

struct Token {
    TokenType type;
    string val;
}

class Lexer {
private:
    string input;
    size_t pos;

    Token text() {
        auto start = pos;
        // (carter): redundant prob remove
        while (pos < input.length && !input[pos..$].startsWith("{{") && !input[pos..$].startsWith("{%")) {
            pos++;
        }
        return Token(TokenType.Text, input[start..pos]);
    }

    Token[] tag(TokenType startType, TokenType endType, string startDelim, string endDelim) {
        Token[] tokens;
        pos += startDelim.length;
        auto tagStart = pos;
        auto tagEnd = input.indexOf(endDelim, pos);
        if (tagEnd == -1) {
            throw new Exception("Missing tag end.\n\tDelimiter: " ~ endDelim ~ "\n\tPosition: " ~ pos.to!string);
        }

        string content = input[tagStart..tagEnd].strip();
        pos = tagEnd + endDelim.length;

        // (carter): {% / %}
        if (startType == TokenType.TagStart) {
            auto parts = content.split();
            auto keyword = parts[0];

            Token[] tagTokens = [Token(startType, startDelim)];
            switch (keyword) {
                case "if":
                    tagTokens ~= Token(TokenType.If, "if");
                    tagTokens ~= Token(TokenType.Expression, content["if".length..$].strip());
                    break;
                case "else":
                    tagTokens ~= Token(TokenType.Else, "else");
                    break;
                case "endif":
                    tagTokens ~= Token(TokenType.EndIf, "endif");
                    break;
                default:
                    tagTokens ~= Token(TokenType.Identifier, content);
                    break;
            }
        }
        return tokens;
    }

public:
    this(string input) {
        this.input = input;
    }

    Token[] tokenize() {
        Token[] tokens;
        while (pos < input.length) {
            if (input[pos..$].startsWith("{{")) {
                // var analysis
            } else if (input[pos..$].startsWith("{%")) {
                // tag analysis
            } else {
                tokens ~= text();
            }
        }
        tokens ~= Token(TokenType.EOF, "");
        return tokens;
    }
}