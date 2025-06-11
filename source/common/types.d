module common.types;


/// (carter):
/// Cheeky, but will be changed to a bespoke type similar to `QueryDict`.
alias Headers = string[string];
alias Cookies = string[string];

enum Encoding {
    NONE
}