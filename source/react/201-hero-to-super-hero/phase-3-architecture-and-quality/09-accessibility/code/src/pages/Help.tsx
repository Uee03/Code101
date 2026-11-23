import PageTitle from '../core/PageTitle';

export default function Help() {
  return (
    <>
      <PageTitle>Help</PageTitle>
      <p>Use this page to practise the keyboard walk. Press Tab and watch where the focus ring goes.</p>
      <h2>Keyboard checklist</h2>
      <ol>
        <li>Press Tab once after the page loads: the "Skip to main content" link appears.</li>
        <li>Open a page from the menu with Enter: focus moves to the page heading.</li>
        <li>On the Tasks page, change a task with the select box only (no mouse).</li>
        <li>Press the delete button, then Escape: the dialog closes and focus returns to the button.</li>
      </ol>
    </>
  );
}
