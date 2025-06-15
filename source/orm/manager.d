module orm.manager;

import orm.queryset;

struct Manager(T) {
    /// all, filter, get, create etc
    auto all() {
        return QuerySet!T();
    }
    private bool _isNew = true;
}
