import { useState } from 'react';
import Panel from '../components/Panel';
import FilterBar from '../components/FilterBar';
import BookList from '../components/BookList';

export default function Home() {
  const [unreadOnly, setUnreadOnly] = useState(false);
  return (
    <Panel title="My books">
      <FilterBar unreadOnly={unreadOnly} onChange={setUnreadOnly} />
      <BookList unreadOnly={unreadOnly} />
    </Panel>
  );
}
