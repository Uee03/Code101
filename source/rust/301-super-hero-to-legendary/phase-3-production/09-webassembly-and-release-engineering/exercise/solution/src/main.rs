use std::collections::HashMap;
use std::sync::Mutex;

#[derive(Debug, PartialEq, Eq)]
pub struct CacheFull;

pub struct Cache {
    max_entries: usize,
    entries: Mutex<HashMap<String, String>>,
}

impl Cache {
    pub fn new(max_entries: usize) -> Self {
        Cache {
            max_entries,
            entries: Mutex::new(HashMap::new()),
        }
    }

    /// Stores a value. A new key is refused when the cache is full; an existing key is replaced.
    pub fn put(&self, key: &str, value: &str) -> Result<(), CacheFull> {
        let mut entries = self.lock();
        if !entries.contains_key(key) && entries.len() >= self.max_entries {
            return Err(CacheFull);
        }
        entries.insert(key.to_string(), value.to_string());
        Ok(())
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.lock().get(key).cloned()
    }

    // The map holds plain strings and every update is a single insert, so it is consistent
    // even if another thread panicked while holding the lock: recover instead of cascading.
    fn lock(&self) -> std::sync::MutexGuard<'_, HashMap<String, String>> {
        self.entries
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }
}

/// Compares the expected secret (from configuration, never from source) with the given one,
/// looking at every byte. Prefer a vetted crate such as `subtle` in real code.
pub fn is_admin(expected: &str, given: &str) -> bool {
    let a = expected.as_bytes();
    let b = given.as_bytes();
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |diff, (x, y)| diff | (x ^ y)) == 0
}

pub fn first_word(line: &str) -> Option<&str> {
    line.split_whitespace().next()
}

pub fn parse_port(text: &str) -> Result<u16, String> {
    match text.trim().parse::<u16>() {
        Ok(port) if port != 0 => Ok(port),
        _ => Err(format!("invalid port: {text:?}")),
    }
}

/// Logs who logged in, never the secret. `{user:?}` escapes control characters and quotes.
pub fn log_login(user: &str) {
    println!("login user={user:?}");
}

fn main() {
    let cache = Cache::new(2);
    println!("{:?}", cache.put("a", "1"));
    println!("{:?}", cache.put("b", "2"));
    println!("{:?}", cache.put("c", "3"));
    println!("{:?}", cache.get("a"));
    println!("{:?}", first_word("hello world"));
    println!("{:?}", first_word(""));
    println!("{:?}", parse_port("8080"));
    println!("{:?}", parse_port("80x"));
    println!("{}", is_admin("s3cret-from-config", "s3cret-from-config"));
    println!("{}", is_admin("s3cret-from-config", "guess"));
    log_login("ana");
}
