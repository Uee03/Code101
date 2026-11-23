export interface Item {
  id: number;
  title: string;
}

export interface Project {
  id: number;
  name: string;
  tasks: Item[];
}

export const PROJECTS: Project[] = [
  {
    id: 1,
    name: 'Platform',
    tasks: [
      { id: 11, title: 'Add the health check' },
      { id: 12, title: 'Write the OpenAPI file' },
      { id: 13, title: 'Seed the database' }
    ]
  },
  {
    id: 2,
    name: 'Docs',
    tasks: [
      { id: 21, title: 'Explain signals' },
      { id: 22, title: 'Record a demo' }
    ]
  },
  { id: 3, name: 'Mobile', tasks: [] }
];
