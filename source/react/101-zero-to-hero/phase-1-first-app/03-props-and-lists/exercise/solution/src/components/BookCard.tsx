type BookCardProps = {
  title: string;
  author: string;
  pages: number;
  read?: boolean;
};

export default function BookCard({ title, author, pages, read = false }: BookCardProps) {
  return (
    <li className="card">
      <h3>{title}</h3>
      <p>
        by {author}, {pages} pages
      </p>
      {pages > 400 && <p className="long">Long read</p>}
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
    </li>
  );
}
