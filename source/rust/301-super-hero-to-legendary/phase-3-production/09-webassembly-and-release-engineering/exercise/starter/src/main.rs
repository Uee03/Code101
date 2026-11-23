use std::collections::HashMap;
use std::sync::Mutex;

const FALLBACK_TOKEN: &str = "admin-secret-123";

pub struct Cache {
    entries: Mutex<HashMap<String, String>>,
}

impl Cache {
    pub fn new() -> Self {
        Cache {
            entries: Mutex::new(HashMap::new()),
        }
    }

    pub fn put(&self, key: &str, value: &str) {
        self.entries
            .lock()
            .unwrap()
            .insert(key.to_string(), value.to_string());
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.entries.lock().unwrap().get(key).cloned()
    }
}

pub fn is_admin(given: &str) -> bool {
    given == FALLBACK_TOKEN
}

pub fn first_word(line: &str) -> &str {
    &line[..line.find(' ').unwrap()]
}

pub fn parse_port(text: &str) -> u16 {
    text.parse().unwrap_or(0)
}

pub fn log_login(user: &str, token: &str) {
    println!("login user={user} token={token}");
}

fn main() {
    let cache = Cache::new();
    cache.put("a", "1");
    println!("{:?}", cache.get("a"));
    println!("{}", first_word("hello world"));
    println!("{}", parse_port("8080"));
    println!("admin: {}", is_admin("admin-secret-123"));
    log_login("ana", "admin-secret-123");
}
