/// The Docker health check reads the raw reply of the server. Healthy means: the first line is
/// `HTTP/1.1 200` followed by a space and a reason phrase. `HTTP/1.1 2000 Odd` and an empty reply are not healthy.
fn is_healthy(reply: &str) -> bool {
    reply.lines().next().is_some_and(|line| line.starts_with("HTTP/1.1 200 "))
}

fn main() {
    let replies = [
        "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\n\r\n{\"status\":\"ok\"}",
        "HTTP/1.1 503 Service Unavailable\r\n\r\n",
        "HTTP/1.1 2000 Odd\r\n\r\n",
        "",
    ];
    for reply in replies {
        println!("{}", is_healthy(reply));
    }
}
