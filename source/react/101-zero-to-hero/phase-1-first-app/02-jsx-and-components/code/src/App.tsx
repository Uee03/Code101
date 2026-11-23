import Header from './components/Header';
import Footer from './components/Footer';

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
        <p className="note">Everything on this page is drawn by components.</p>
        {/* This comment is not shown on the page. */}
      </main>
      <Footer />
    </>
  );
}
