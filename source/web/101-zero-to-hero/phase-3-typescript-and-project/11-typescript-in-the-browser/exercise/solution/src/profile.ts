export interface Profile {
  name: string;
  bio: string;
  skills: string[];
}
export function heading(name: string): string {
  return "Meet " + name;
}
