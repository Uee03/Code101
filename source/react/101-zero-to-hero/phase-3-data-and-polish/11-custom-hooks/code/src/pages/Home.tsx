import Panel from '../components/Panel';
import FilterBar from '../components/FilterBar';
import BookList from '../components/BookList';
import { useBooks } from '../BooksContext';
import useLocalStorage from '../hooks/useLocalStorage';
import usePageTitle from '../hooks/usePageTitle';

export default function Home() {
  const [unreadOnly, setUnreadOnly] = useLocalStorage('reading-list.unreadOnly', false);
  const { books, status } = useBooks();
  const unread = books.filter((book) => !book.read).length;
  usePageTitle(status === 'success' ? `Reading list (${unread} unread)` : 'Reading list');
  return (
    <Panel title="My books">
      <FilterBar unreadOnly={unreadOnly} onChange={setUnreadOnly} />
      <BookList unreadOnly={unreadOnly} />
    </Panel>
  );
}
