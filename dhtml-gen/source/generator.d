module generator;

import parser;
import std.array;
import std.format;
import std.algorithm;
import std.sumtype;
import std.string;

class Generator {
private:
    TemplateNode ast;
    Appender!string code;

    void visit(AstNode node) {
        node.match!(
            (TextNode n)        => visitText(n),
            (ExpressionNode n)  => visitExpression(n),
            (IfNode n)          => visitIf(n)
        );
    }

    void visitText(TextNode node) {
        if (node.content.strip().length > 0) {
            code.put(format("    result.put(`%s`);\n", node.content));
        }
    }

    void visitExpression(ExpressionNode node) {
        code.put(format("    result.put(to!string(%s));\n", node.expression));
    }

    void visitIf(IfNode node) {
        code.put(format("    if (%s) {\n", node.condition));
        foreach (bodyNode; node.body) {
            visit(bodyNode);
        }
        code.put("    }");

        if (node.elseBody.length > 0) {
            code.put(" else {\n");
            foreach (elseNode; node.elseBody) {
                visit(elseNode);
            }
            code.put("    }");
        }
        code.put("\n");
    }

public:
    this(TemplateNode ast) {
        this.ast = ast;
        this.code = appender!string;
    }

    string generate(string modulePath) {
        code.put(format("module %s;\n\n", modulePath));

        code.put("import std.array : appender;\n");
        code.put("import std.conv : to;\n");

        code.put(format("string %s(", ast.name));
        foreach (i, param; ast.params) {
            code.put(format("%s %s", param.type, param.name));
            if (i < ast.params.length - 1) {
                code.put(", ");
            }
        }
        code.put(") {\n");

        code.put("    auto result = appender!string;\n\n");
        foreach (node; ast.body) {
            visit(node);
        }
        code.put("\n    return result.data;\n");
        code.put("}\n");

        return code.data;
    }
}
