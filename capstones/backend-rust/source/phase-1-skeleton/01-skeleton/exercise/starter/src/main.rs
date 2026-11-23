const PROBLEM_BASE: &str = "https://code101.example/problems/";

/// The last part of the `type` URL for an HTTP status, as the contract lists them:
/// 400 bad-request, 401 unauthorized, 403 forbidden, 404 not-found, 409 conflict,
/// 412 precondition-failed, 422 validation-error, 428 precondition-required, 429 rate-limited,
/// and internal-error for everything else.
fn problem_slug(status: u16) -> &'static str {
    todo!("map {status} to a slug")
}

fn main() {
    for status in [400, 401, 403, 404, 409, 412, 422, 428, 429, 500] {
        println!("{status} {PROBLEM_BASE}{}", problem_slug(status));
    }
}
