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

    // TODO 1: make close() return a Connection<Closed> that keeps host and sent.
    pub fn close(self) -> Connection<Closed> {
        todo!("move host and sent into a Connection<Closed>")
    }
}

impl<S> Connection<S> {
    pub fn host(&self) -> &str {
        &self.host
    }

    // TODO 2: return how many messages were sent so far, in every state.
    pub fn sent(&self) -> u32 {
        todo!("return the sent counter")
    }
}

fn main() {
    let conn = Connection::new("db.internal").open().send("hello").send("again");
    let closed = conn.close();
    println!("{} sent {} message(s)", closed.host(), closed.sent());
    let reopened = closed.open();
    println!("reopened, still {} sent", reopened.sent());
}
