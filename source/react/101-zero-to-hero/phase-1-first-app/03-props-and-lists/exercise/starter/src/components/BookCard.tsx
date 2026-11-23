type BookCardProps = {
  title: string;
  author: string;
  pages: number;
  read?: boolean;
};

export default function BookCard({ title, author, pages, read = false }: BookCardProps) {
  // TODO: when pages is more than 400, show <p className="long">Long read</p> under the author line.
  return (
    <li className="card">
      <h3>{title}</h3>
      <p>
        by {author}, {pages} pages
      </p>
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
    </li>
  );
}
