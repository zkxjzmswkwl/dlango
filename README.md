# Dlango
I really like Django, but I'm not in love with Python. It's nice. D is better.

## Constraints for the sake of constraints
Personally I won't be using AI assistance for code generation or linting, with perhaps one exception--security. In my view, not augmenting security audits with powerful tools is foolish. 

I want to refrain from using AI assistance for code generation and linting because I enjoy programming. I enjoy not knowing and I enjoy figuring it out on my own. I acknowledge that this will make the project take longer. I'm fine with that.


# Usage
Dlango uses code-generated database schemas.

```d
struct User {
    /// bakes in orm functionality + id field.
    mixin Model!User;

    string username;
    string email;
    string password;
    long createdAt;

    this (string username, string email, string password) {
        this.username = username;
        this.email = email;
        this.password = password;
    }
}
```

Once you run `makemigrations` and `migrate`, the schema is in place. Migrations are stored in `source/migrations/` along with a `manifest`.

### Querying
```d
User("retrac", "retrac@gmail.com", "password").save();

auto filtered = User.objects.filter([
	Q("email__iexact", "RETRAC@gmail.com")
]);

foreach (user; filtered) {
	writeln(user.username, " ", user.email, " ", user.ID);
}
// Output: retrac retrac@gmail.com 1
```

## Compiler
Only ~~promise~~ *hope* is that this will compile with ldc2. DMD has never treated me right.