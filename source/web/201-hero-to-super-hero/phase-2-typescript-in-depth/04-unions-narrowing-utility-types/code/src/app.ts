import {
  STATUS_LABELS,
  applyEvent,
  describeEvent,
  formatNote,
  groupByStatus,
  parseStatus,
  statusLabel,
  toSummary,
  updateTask,
  type Task,
  type TaskEvent,
} from "./tasks.js";

const events: TaskEvent[] = [
  { kind: "created", task: { id: 1, title: "Write lesson", status: "todo" } },
  { kind: "created", task: { id: 2, title: "Review lesson", status: "todo", note: "ask a colleague" } },
  { kind: "moved", id: 1, to: "doing" },
  { kind: "moved", id: 2, to: parseStatus("done") },
  { kind: "deleted", id: 2 },
];

let tasks: Task[] = [];
for (const event of events) {
  console.log(describeEvent(event));
  tasks = applyEvent(tasks, event);
}

const groups = groupByStatus(tasks);
for (const status of ["todo", "doing", "done"] as const) {
  console.log(`${STATUS_LABELS[status]}: ${groups[status].length}`);
}

console.log(JSON.stringify(tasks.map(toSummary)));
console.log(statusLabel(tasks[0]), statusLabel({ id: 9, title: "Loose" }));

const renamed = updateTask(tasks[0], { title: "Write lesson 04", note: "draft" });
console.log(renamed.title, "|", formatNote(renamed.note));
console.log(formatNote(undefined));
console.log(formatNote(["a", "b"]));

try {
  parseStatus("blocked");
} catch (error) {
  if (error instanceof Error) {
    console.log(error.message);
  }
}
