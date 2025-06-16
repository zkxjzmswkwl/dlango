module orm.q;

import orm.db : DbValue;

struct Q {
    string lookup;
    DbValue value;

    this (Value)(string lookup, Value val) {
        this.lookup = lookup;
        this.value = DbValue(val);
    }
}