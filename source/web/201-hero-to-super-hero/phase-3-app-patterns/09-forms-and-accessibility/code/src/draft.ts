export type Priority = "low" | "normal" | "high";

export interface TaskDraft {
  title: string;
  due: string;
  priority: Priority;
  notes: string;
}

function isPriority(value: unknown): value is Priority {
  return value === "low" || value === "normal" || value === "high";
}

export function readDraft(form: HTMLFormElement): TaskDraft | null {
  const data = new FormData(form);
  const title = data.get("title");
  const due = data.get("due");
  const priority = data.get("priority");
  const notes = data.get("notes");
  if (typeof title !== "string" || typeof due !== "string" || !isPriority(priority)) {
    return null;
  }
  return { title: title.trim(), due, priority, notes: typeof notes === "string" ? notes.trim() : "" };
}

export function todayLocal(): string {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}
