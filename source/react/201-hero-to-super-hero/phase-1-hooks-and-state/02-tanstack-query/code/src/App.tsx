import Board from './components/Board';

export default function App() {
  return (
    <main>
      <h1>Query lab</h1>
      <p>
        A task whose title contains the word &quot;fail&quot; cannot be moved: the fake server refuses, and the board rolls back.
      </p>
      <Board />
    </main>
  );
}
