import Header from './components/Header';
import Footer from './components/Footer';
import Panel from './components/Panel';
import BookList from './components/BookList';
import Counter from './components/Counter';

export default function App() {
  return (
    <>
      <Header />
      <main>
        <Panel title="My books">
          <BookList />
        </Panel>
        <Panel title="About">
          <p>A small app that grows lesson by lesson.</p>
          <Counter />
        </Panel>
      </main>
      <Footer />
    </>
  );
}
