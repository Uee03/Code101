export interface Comment {
  readonly name: string;
  readonly message: string;
  readonly website: string;
}

export function cleanComment(name: string, message: string, website: string): Comment | null {
  const cleaned = { name: name.trim(), message: message.trim(), website: website.trim() };
  if (cleaned.name === "" || cleaned.message === "") {
    return null;
  }
  if (cleaned.name.length > 40 || cleaned.message.length > 200) {
    return null;
  }
  return cleaned;
}
