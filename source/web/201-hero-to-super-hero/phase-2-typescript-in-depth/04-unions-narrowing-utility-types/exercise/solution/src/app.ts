import { applyEvent, groupByStatus, type Task, type TaskEvent, type TaskStatus } from "./tasks.js";

const events: TaskEvent[] = [
  { kind: "created", task: { id: 1, title: "Write lesson", status: "todo" } },
  { kind: "created", task: { id: 2, title: "Review lesson", status: "todo" } },
  { kind: "moved", id: 1, to: "doing" },
  { kind: "moved", id: 2, to: "doing" },
  { kind: "moved", id: 2, to: "done" },
];

function titlesByStatus(tasks: readonly Task[]): Record<TaskStatus, string[]> {
  const groups = groupByStatus(tasks);
  return {
    todo: groups.todo.map((task) => task.title),
    doing: groups.doing.map((task) => task.title),
    done: groups.done.map((task) => task.title),
  };
}

type MovedEvent = Extract<TaskEvent, { kind: "moved" }>;
function isMoved(event: TaskEvent): event is MovedEvent {
  return event.kind === "moved";
}

const tasks = events.reduce<Task[]>((current, event) => applyEvent(current, event), []);
console.log(JSON.stringify(titlesByStatus(tasks)));
console.log(`Moved events: ${events.filter(isMoved).length}`);
