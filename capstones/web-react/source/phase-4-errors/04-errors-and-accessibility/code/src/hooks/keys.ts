export const keys = {
  list: (area: string, id: string, filters: object) => [area, id, filters] as const,
  entity: (area: string, id: string) => [area, id] as const,
};
