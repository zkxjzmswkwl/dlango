module orm.schema;

import std.conv : to;
import asdf;

struct FieldSchema {
    string nativeType;
    string sqlType;

    bool opEquals(const FieldSchema other) const {
        return nativeType == other.nativeType && sqlType == other.sqlType;
    }

    string toJSON() {
        return this.serializeToJson().to!string;
    }
}

struct ModelSchema {
    FieldSchema[string] fields;

    bool opEquals(const ModelSchema other) const {
        return fields == other.fields;
    }

    string toJSON() {
        return this.serializeToJson().to!string;
    }
}

struct ProjectSchema {
    ModelSchema[string] models;

    string toJSON() {
        return this.serializeToJson().to!string;
    }

    ModelSchema opIndex(string tableName) {
        return models[tableName];
    }

    void opIndexAssign(ModelSchema modelSchema, string tableName) {
        models[tableName] = modelSchema;
    }
}
