export type Book = {
  id: number;
  title: string;
  author: string;
  pages: number;
  read: boolean;
};

export const books: Book[] = [
  { id: 1, title: 'A Field Guide to Birds', author: 'Mira Lind', pages: 320, read: true },
  { id: 2, title: 'Cooking with Beans', author: 'Tomas Reyes', pages: 180, read: false },
  { id: 3, title: 'The Quiet Garden', author: 'Hana Okafor', pages: 450, read: false },
  { id: 4, title: 'Night Trains', author: 'Jonas Weber', pages: 260, read: true },
];
