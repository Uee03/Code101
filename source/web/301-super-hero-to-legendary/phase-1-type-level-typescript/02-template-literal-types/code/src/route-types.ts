// Split "a.b.c" at a delimiter into ["a", "b", "c"].
export type Split<S extends string, D extends string> = S extends `${infer Head}${D}${infer Tail}`
  ? [Head, ...Split<Tail, D>]
  : [S];

// Extract the names of ":param" segments from a route pattern.
export type PathParams<P extends string> = P extends `${string}:${infer Param}/${infer Rest}`
  ? Param | PathParams<`/${Rest}`>
  : P extends `${string}:${infer Param}`
    ? Param
    : never;

export type RouteParams<P extends string> = { [K in PathParams<P>]: string };

// Routes without parameters take no second argument; others take exactly one params object.
export type ParamArgs<P extends string> = [PathParams<P>] extends [never]
  ? []
  : [params: RouteParams<P>];

// "due_date" becomes "dueDate" (type level).
export type SnakeToCamel<S extends string> = S extends `${infer Head}_${infer Tail}`
  ? `${Head}${Capitalize<SnakeToCamel<Tail>>}`
  : S;

// Rename every string key of an object type.
export type CamelizeKeys<T> = {
  [K in keyof T as K extends string ? SnakeToCamel<K> : K]: T[K];
};
