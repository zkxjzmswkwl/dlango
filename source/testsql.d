module testsql;

import d2sqlite3;
import std.typecons : Nullable;


void go() {
    auto db = Database("test.db");
    db.run("DROP TABLE IF EXISTS person;
            CREATE TABLE person (
            id     INTEGER PRIMARY KEY,
            name   TEXT NOT NULL,
            score  FLOAT)");
    Statement st = db.prepare("INSERT INTO person (name, score) VALUES (:name, :score)");
    st.bind(":name", "John");
    st.bind(":score", 100.0);
    st.execute();
    st.reset();
}
