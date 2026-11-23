import Header from './components/Header';
import Footer from './components/Footer';
// TODO 2: import Tip from './components/Tip';

export default function App() {
  const owner = 'Ada';
  const goal = 12;
  return (
    <>
      <Header />
      <main>
        <h2>Welcome, {owner}</h2>
        <p>
          Your goal is {goal} books this year. That is {goal / 12} a month.
        </p>
        {/* TODO 3: show the Tip component here, twice. */}
      </main>
      <Footer />
    </>
  );
}
