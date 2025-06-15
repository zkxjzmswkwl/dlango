module orm.models;

import orm.manager;
import std.meta;

template Model(T) {
    /// (carter):
    /// save, delete, etc.

    static auto objects() { return Manager!T();}
}

struct User {
	mixin Model!User;

	string username;
	string emal;
	int age;
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

alias AllModels = AliasSeq!(User, Song);