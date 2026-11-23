import { applyEvent, groupByStatus, type Task, type TaskEvent, type TaskStatus } from "./tasks.js";

const events: TaskEvent[] = [
  { kind: "created", task: { id: 1, title: "Write lesson", status: "todo" } },
  { kind: "created", task: { id: 2, title: "Review lesson", status: "todo" } },
  { kind: "moved", id: 1, to: "doing" },
  { kind: "moved", id: 2, to: "doing" },
  { kind: "moved", id: 2, to: "done" },
];

// TODO 1: return the titles for each status, for example { todo: [], doing: ["A"], done: ["B"] }.
function titlesByStatus(tasks: readonly Task[]): Record<TaskStatus, string[]> {
  throw new Error("TODO 1");
}

// TODO 2: define MovedEvent with Extract<TaskEvent, { kind: "moved" }> and finish the type guard.
type MovedEvent = never;
function isMoved(event: TaskEvent): event is MovedEvent {
  throw new Error("TODO 2");
}

const tasks = events.reduce<Task[]>((current, event) => applyEvent(current, event), []);
console.log(JSON.stringify(titlesByStatus(tasks)));
console.log(`Moved events: ${events.filter(isMoved).length}`);
