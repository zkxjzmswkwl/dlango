module orm.models;

import orm.manager;
import std.meta;
import std.traits;
import std.string;
import std.array;
import orm.db;
import orm.intro;
import std.datetime;
import std.sumtype;
import std.conv;


template Model(T) {
    private bool _isNew = true;
    private long id;

    static auto objects() { return Manager!T();}
    void save() {
        auto db = getDbConnection();

        if (_isNew) {
            string[] columns;
            string[] placeholders;
            DbValue[] values;

            static foreach(member; __traits(allMembers, typeof(this))) {
                static if (member != "id" && member != "objects" && member != "save" && member[0] != '_' && member != "ID") {
                    columns ~= member;
                    placeholders ~= "?";
                    mixin("values ~= DbValue(this." ~ member ~ ");");
                }
            }

            string sql = "INSERT INTO " ~ ModelInfo!(typeof(this)).tableName ~ 
                         " (" ~ columns.join(", ") ~ ") VALUES (" ~ placeholders.join(", ") ~ ");";
            
            auto stmt = db.prepare(sql);
            
            foreach(i, param; values) {
                param.match!(
                    (long v)   => stmt.bind(cast(int)(i + 1), v),
                    (string v) => stmt.bind(cast(int)(i + 1), v),
                    (double v) => stmt.bind(cast(int)(i + 1), v),
                    (Date v)   => stmt.bind(cast(int)(i + 1), v.toSimpleString()),
                );
            }
            stmt.execute();
            
            this.id = db.lastInsertRowid;
            this._isNew = false;

        } else {
            string[] setClauses;
            DbValue[] values;

            static foreach(member; __traits(allMembers, typeof(this))) {
                static if (member != "id" && member != "objects" && member != "save" && member[0] != '_') {
                    setClauses ~= member ~ " = ?";
                    mixin("values ~= DbValue(this." ~ member ~ ");");
                }
            }
            
            values ~= DbValue(this.id);
            
            string sql = "UPDATE " ~ ModelInfo!(typeof(this)).tableName ~
                         " SET " ~ setClauses.join(", ") ~ " WHERE id = ?;";
                         
            auto stmt = db.prepare(sql);

            foreach(i, param; values) {
                param.match!(
                    (long v)   => stmt.bind(cast(int)(i + 1), v),
                    (string v) => stmt.bind(cast(int)(i + 1), v),
                    (double v) => stmt.bind(cast(int)(i + 1), v),
                    (Date v)   => stmt.bind(cast(int)(i + 1), v.toSimpleString()),
                );
            }
            stmt.execute();
        }
    }

    auto ID() @property {
        return this.id;
    }
}

struct MoneyMethod {
    mixin Model!MoneyMethod;

    string title;
    string category;
    string intensity;
    long profit;

    this(string title, string category, string intensity, long profit) {
        this.title = title;
        this.category = category;
        this.intensity = intensity;
        this.profit = profit;
    }
}

struct User {
	mixin Model!User;

	string username;
	string email;
    string password;
    int createdAt;

    this(string username, string email, string password) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.createdAt = Clock.currTime().toUnixTime();
    }
}

struct Song {
    mixin Model!Song;
    string title;
    string artist;
    string album;
    int year;
    int duration;
    string genre;
    string path;
    string description;
}

struct Product {
    mixin Model!Product;
    string name;
    string description;
    string price;
    string category;
}

struct Game {
    mixin Model!Game;
    string name;
    string description;
    string price;
    string category;
}

alias AllModels = AliasSeq!(User, MoneyMethod);