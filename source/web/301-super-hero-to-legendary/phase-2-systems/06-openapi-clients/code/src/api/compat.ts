// Mutual assignability: the two types describe the same set of values.
export type Assignable<A, B> = [A] extends [B] ? ([B] extends [A] ? true : false) : false;
export type Expect<T extends true> = T;
