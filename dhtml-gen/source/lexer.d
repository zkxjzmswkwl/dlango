module lexer;

import std.string;
import std.conv;
import std.exception;

enum TokenType {
    Text,
    VarStart,
    VarEnd,

    TagStart,
    TagEnd,
    If,
    Else,
    EndIf,
    Expression,

    Dtml,
    Identifier,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Comma,

    EOF
}

struct Token {
    TokenType type;
    string value;
}

class Lexer {
private:
    string input;
    size_t pos;

    bool isWhite(char c) {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }

    bool isAlphaNum(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
    }

    void skipWhitespace() {
        while (pos < input.length && isWhite(input[pos])) {
            pos++;
        }
    }

    Token lexText() {
        auto start = pos;
        while (pos < input.length && 
               !input[pos..$].startsWith("{{") && 
               !input[pos..$].startsWith("{%") &&
               input[pos] != '}') {
            pos++;
        }
        return Token(TokenType.Text, input[start..pos]);
    }

    Token[] lexInnerTag(TokenType startType, TokenType endType, string startDelim, string endDelim) {
        pos += startDelim.length;
        
        auto tagEnd = input.indexOf(endDelim, pos);
        enforce(tagEnd != -1, "Unclosed tag. Expected '" ~ endDelim ~ "'.");

        string content = input[pos..tagEnd].strip();
        pos = tagEnd + endDelim.length;
        
        Token[] tokens;
        tokens ~= Token(startType, startDelim);

        if (startType == TokenType.TagStart) {
            auto parts = content.split();
            auto keyword = parts[0];
            switch (keyword) {
                case "if":
                    tokens ~= Token(TokenType.If, "if");
                    tokens ~= Token(TokenType.Expression, content["if".length..$].strip());
                    break;
                case "else":
                    tokens ~= Token(TokenType.Else, "else");
                    break;
                case "endif":
                    tokens ~= Token(TokenType.EndIf, "endif");
                    break;
                default:
                    throw new Exception("Unsupported tag keyword: " ~ keyword);
            }
        } else {
            tokens ~= Token(TokenType.Expression, content);
        }

        tokens ~= Token(endType, endDelim);
        return tokens;
    }

    Token lexIdentifier() {
        skipWhitespace();
        auto start = pos;
        while (pos < input.length && (isAlphaNum(input[pos]) || input[pos] == '_' || input[pos] == '.')) {
            pos++;
        }
        enforce(start != pos, "Expected an identifier.");
        return Token(TokenType.Identifier, input[start..pos]);
    }

public:
    this(string input) {
        this.input = input;
    }

    Token[] tokenize() {
        Token[] tokens;
        
        skipWhitespace();
        enforce(input[pos..$].startsWith("dtml"), "Template must start with 'dtml' keyword.");
        tokens ~= Token(TokenType.Dtml, "dtml");
        pos += "dtml".length;

        tokens ~= lexIdentifier();

        skipWhitespace();
        enforce(input[pos] == '(', "Expected '(' after component name.");
        tokens ~= Token(TokenType.LParen, "(");
        pos++;

        while (true) {
            skipWhitespace();
            if (input[pos] == ')') break;
            
            tokens ~= lexIdentifier();
            tokens ~= lexIdentifier();

            skipWhitespace();
            if (input[pos] == ',') {
                tokens ~= Token(TokenType.Comma, ",");
                pos++;
            } else {
                break;
            }
        }

        enforce(input[pos] == ')', "Expected ')' or ',' in parameter list.");
        tokens ~= Token(TokenType.RParen, ")");
        pos++;

        skipWhitespace();
        enforce(input[pos] == '{', "Expected '{' to start template body.");
        tokens ~= Token(TokenType.LBrace, "{");
        pos++;

        while (pos < input.length) {
            if (input[pos..$].startsWith("{{")) {
                tokens ~= lexInnerTag(TokenType.VarStart, TokenType.VarEnd, "{{", "}}");
            } else if (input[pos..$].startsWith("{%")) {
                tokens ~= lexInnerTag(TokenType.TagStart, TokenType.TagEnd, "{%", "%}");
            } else if (input[pos] == '}') {
                tokens ~= Token(TokenType.RBrace, "}");
                pos++;
                break;
            } else {
                auto textToken = lexText();
                if (textToken.value.length > 0) {
                    tokens ~= textToken;
                }
            }
        }
        
        tokens ~= Token(TokenType.EOF, "");
        return tokens;
    }
}
