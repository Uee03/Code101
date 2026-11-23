import { Link } from 'react-router';

type BookCardProps = {
  id: number;
  title: string;
  author: string;
  pages: number;
  read: boolean;
  onToggle: (id: number) => void;
};

export default function BookCard({ id, title, author, pages, read, onToggle }: BookCardProps) {
  return (
    <li className="card">
      <h3>
        <Link to={`/books/${id}`}>{title}</Link>
      </h3>
      <p>
        by {author}, {pages} pages
      </p>
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
      <button type="button" onClick={() => onToggle(id)}>
        {read ? 'Mark as unread' : 'Mark as read'}
      </button>
    </li>
  );
}
