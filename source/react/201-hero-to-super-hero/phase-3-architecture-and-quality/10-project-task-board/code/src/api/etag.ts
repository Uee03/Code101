// The contract defines the ETag as the quoted resource version, for example "3".
// The capstone keeps the header value it received; this project builds it from the version in the list.
export function etagFor(version: number): string {
  return `"${version}"`;
}
