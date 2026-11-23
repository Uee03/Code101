import Panel from '../components/Panel';
import BookList from '../components/BookList';

export default function Home() {
  return (
    <Panel title="My books">
      <BookList />
    </Panel>
  );
}
