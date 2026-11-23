use std::marker::PhantomData;

pub struct Closed;
pub struct Open;

pub struct Connection<S> {
    host: String,
    sent: u32,
    state: PhantomData<S>,
}

impl Connection<Closed> {
    pub fn new(host: &str) -> Self {
        Connection {
            host: host.to_string(),
            sent: 0,
            state: PhantomData,
        }
    }

    pub fn open(self) -> Connection<Open> {
        Connection {
            host: self.host,
            sent: self.sent,
            state: PhantomData,
        }
    }
}

impl Connection<Open> {
    pub fn send(mut self, _message: &str) -> Self {
        self.sent += 1;
        self
    }

    pub fn close(self) -> Connection<Closed> {
        Connection {
            host: self.host,
            sent: self.sent,
            state: PhantomData,
        }
    }
}

impl<S> Connection<S> {
    pub fn host(&self) -> &str {
        &self.host
    }

    pub fn sent(&self) -> u32 {
        self.sent
    }
}

fn main() {
    let conn = Connection::new("db.internal").open().send("hello").send("again");
    let closed = conn.close();
    println!("{} sent {} message(s)", closed.host(), closed.sent());
    let reopened = closed.open();
    println!("reopened, still {} sent", reopened.sent());
}
