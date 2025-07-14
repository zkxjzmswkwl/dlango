# Dlango
I really like Django, but I'm not in love with Python. It's nice. D is better.

If you would like to talk about the project, join the official [Dlang Discord](https://discord.gg/abu7BnnBZ7) and ping me (`._carter`) in either `#webdev` or `#programming`.

## Constraints for the sake of constraints
Personally I won't be using AI assistance for code generation or linting, with perhaps one exception--security. In my view, not augmenting security audits with powerful tools is foolish. 

I want to refrain from using AI assistance for code generation and linting because I enjoy programming. I enjoy not knowing and I enjoy figuring it out on my own. I acknowledge that this will make the project take longer. I'm fine with that.

# Quickstart
- build `dlangoadmin` project.
- place `dlango-admin`/`.exe` in your path.
- create new project: `dlango-admin createproject --name=projectname`
- As of writing, the generated project does not start a webserver or provide a convenient way for you to add routes (June 25).
  - I will fix this tomorrow night.

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
}
```

Once you run `makemigrations` and `migrate`, the schema is in place. Migrations are stored in `source/migrations/` along with a `manifest`.

### Querying
```d
User("retrac", "retrac@gmail.com", "password").save();

auto filtered = User.objects.filter(
	Q("email__iexact", "RETRAC@gmail.com"),
  Q("username__exact", "retrac")
);

foreach (user; filtered) {
	writeln(user.username, " ", user.email, " ", user.ID);
}
// Output: retrac retrac@gmail.com 1
```

### Field lookups
As you may have noticed, field lookups are currently very similar to Django field lookups.
- `exact`: Field must exactly match the value.
- `iexact`: Case-insensitive exact match (value is lowercased before comparison).
- `contains`: Field contains the value (uses `LIKE '%value%'`).
- `gt`: Greater than (`>`).
- `gte`: Greater than or equal (`>=`).
- `lt`: Less than (`<`).
- `lte`: Less than or equal (`<=`).
- `startswith`: Field starts with the value (uses `LIKE 'value%'`).
- `endswith`: Field ends with the value (uses `LIKE '%value'`).
- `in`: Field value must be in a given list (uses `IN`).
- `isnull`: Field must be NULL (uses `IS NULL`).

## Compiler
Only ~~promise~~ *hope* is that this will compile with ldc2. DMD has never treated me right.