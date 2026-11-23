/// The `aud` claim of a token is either one string or a list of strings.
enum Audience {
    One(&'static str),
    Many(&'static [&'static str]),
}

/// True when the token was issued for `wanted`, whichever form `aud` has.
fn audience_ok(aud: &Audience, wanted: &str) -> bool {
    match aud {
        Audience::One(single) => *single == wanted,
        Audience::Many(list) => list.contains(&wanted),
    }
}

/// The effective permission is the intersection of the scope and the role: both must be present.
fn may_read_audit_log(scopes: &[&str], roles: &[&str]) -> bool {
    scopes.contains(&"tasks:admin") && roles.contains(&"admin")
}

fn main() {
    println!("{}", audience_ok(&Audience::One("tasks-api"), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account", "tasks-api"]), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account"]), "tasks-api"));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["member"]));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["admin"]));
}
