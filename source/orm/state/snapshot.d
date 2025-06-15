module orm.state.snapshot;

import asdf;
import std.stdio;
import std.conv : to;
import orm.schema;
import orm.models;

struct SnapshotField {
    string nativeType;
    string sqlType;
}

struct SnapshotModelMeta {
    string primaryKey;
}

struct SnapshotModelInfo {
    SnapshotField[string] fields;
    SnapshotModelMeta meta;
}

struct SnapshotSchema {
    int version_;
    SnapshotModelInfo[string] models;

    static SnapshotSchema fromJSON(string json) {
        return json.deserialize!SnapshotSchema;
    }

    string toJSON() {
        return this.serializeToJson().to!string;
    }
}

ProjectSchema buildNowSchema() {
    import orm.intro;

	ProjectSchema currentState;
	static foreach(T; AllModels) {
        {
            ModelSchema modelSchema;
            foreach (field; ModelInfo!T.fields) {
                modelSchema.fields[field.name] = FieldSchema(field.nativeType, field.sqlType);
            }
            currentState[ModelInfo!T.tableName] = modelSchema;
        }
	}
    return currentState;
}

ProjectSchema loadSnapshotSchema() {
    import std.file : readText;
    import std.conv : to;
    return readText(".orm_snapshot.json").deserialize!ProjectSchema;
}
