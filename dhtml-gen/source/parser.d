module parser;

import std.sumtype;
import lexer;
import std.conv;
import std.exception;

struct Parameter {
    string type;
    string name;
}

struct TextNode {
    string content;
}

struct ExpressionNode {
    string expression;
}

struct IfNode {
    string condition;
    AstNode[] body;
    AstNode[] elseBody;
}

alias AstNode = SumType!(TextNode, ExpressionNode, IfNode);

struct TemplateNode {
    string name;
    Parameter[] params;
    AstNode[] body;
}


class Parser {
private:
    Token[] tokens;
    size_t pos;

    Token current() {
        if (pos < tokens.length) {
            return tokens[pos];
        }
        return Token(TokenType.EOF, "");
    }

    void consume() {
        if (pos < tokens.length) {
            pos++;
        }
    }

    Token expect(TokenType type, string message) {
        auto token = current();
        enforce(token.type == type, message);
        consume();
        return token;
    }

    AstNode[] parseBody(const(TokenType)[] stopAt) {
        AstNode[] nodes;
        while(true) {
            auto t = current.type;
            if (t == TokenType.EOF || t == TokenType.RBrace) break;
            
            if (t == TokenType.TagStart && pos + 1 < tokens.length) {
                auto nextTagType = tokens[pos + 1].type;
                foreach(stopType; stopAt) {
                    if (nextTagType == stopType) return nodes;
                }
            }
            
            nodes ~= parseBodyNode();
        }
        return nodes;
    }

    AstNode parseBodyNode() {
        switch (current.type) {
            case TokenType.Text:
                return AstNode(TextNode(expect(TokenType.Text, "").value));
            
            case TokenType.VarStart:
                expect(TokenType.VarStart, "");
                auto expr = expect(TokenType.Expression, "Expected expression inside {{ }}");
                expect(TokenType.VarEnd, "Expected }}");
                return AstNode(ExpressionNode(expr.value));

            case TokenType.TagStart:
                expect(TokenType.TagStart, "");
                if (current.type == TokenType.If) {
                    return parseIf();
                }
                throw new Exception("Unsupported tag: " ~ current.value);
            
            default:
                throw new Exception("Unexpected token in template body: " ~ current.value);
        }
    }

    AstNode parseIf() {
        expect(TokenType.If, "");
        auto condition = expect(TokenType.Expression, "Expected condition for if-tag.");
        expect(TokenType.TagEnd, "Expected %} after if-condition.");

        auto body = parseBody([TokenType.Else, TokenType.EndIf]);
        AstNode[] elseBody;

        if (current.type == TokenType.TagStart && tokens[pos + 1].type == TokenType.Else) {
            expect(TokenType.TagStart, "");
            expect(TokenType.Else, "");
            expect(TokenType.TagEnd, "");
            elseBody = parseBody([TokenType.EndIf]);
        }

        expect(TokenType.TagStart, "");
        expect(TokenType.EndIf, "If tag was never closed. Expected {% endif %}.");
        expect(TokenType.TagEnd, "");

        return AstNode(IfNode(condition.value, body, elseBody));
    }

public:
    this(Token[] tokens) {
        this.tokens = tokens;
    }

    TemplateNode parse() {
        expect(TokenType.Dtml, "Template must start with 'dtml' keyword.");
        auto componentName = expect(TokenType.Identifier, "Expected component name after 'dtml'.");
        expect(TokenType.LParen, "Expected '(' after component name.");

        Parameter[] params;
        if (current.type != TokenType.RParen) {
            while(true) {
                auto paramType = expect(TokenType.Identifier, "Expected parameter type.");
                auto paramName = expect(TokenType.Identifier, "Expected parameter name.");
                params ~= Parameter(paramType.value, paramName.value);

                if (current.type == TokenType.RParen) break;
                expect(TokenType.Comma, "Expected ',' or ')' in parameter list.");
            }
        }
        expect(TokenType.RParen, "Expected ')' to close parameter list.");
        
        expect(TokenType.LBrace, "Expected '{' to start template body.");
        auto body = parseBody(null);
        expect(TokenType.RBrace, "Expected '}' to close template body.");
        
        return TemplateNode(componentName.value, params, body);
    }
}
