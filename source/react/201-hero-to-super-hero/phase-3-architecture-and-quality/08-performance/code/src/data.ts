export type Task = {
  id: number;
  title: string;
  topic: string;
  done: boolean;
};

const topics = ['Write docs', 'Fix a bug', 'Review code', 'Plan the sprint', 'Update the roadmap'];

export function makeTasks(count: number): Task[] {
  return Array.from({ length: count }, (_, index) => {
    const topic = topics[index % topics.length] ?? 'Other';
    return { id: index + 1, title: `Task ${index + 1}: ${topic}`, topic, done: false };
  });
}
