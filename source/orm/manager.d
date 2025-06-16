module orm.manager;

import orm.queryset;

struct Manager(T) {
    auto all() {
        return QuerySet!T();
    }

    auto create(T_LITERAL)(T_LITERAL literal) {
        T newInstance;

        static foreach(memberName; __traits(allMembers, T_LITERAL)) {
            static if (!__traits(hasMember, T, memberName)) {
                static assert(0, "Model '" ~ T.stringof ~ "' has no field named '" ~ memberName ~ "'.");
            }
            auto value = __traits(getMember, literal, memberName);
            __traits(getMember, newInstance, memberName) = value;
        }

        newInstance.save();
        return newInstance;
    }

    auto get(Args...)(string clause, Args params) {
        return all().get(clause, params);
    }
}
