const result = document.querySelector('#result');
const untrusted = '<img src=x onerror="alert(1)">hello';

function escapeHtml(text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

// The only policy the CSP allows ("trusted-types app"). A real one would sanitise with a library
// instead of escaping everything, so that some safe markup survives.
const policy = window.trustedTypes?.createPolicy('app', {
  createHTML: (input) => escapeHtml(input),
});

function show(message) {
  result.textContent = message;
}

document.querySelector('#inline-handler').addEventListener('click', () => {
  try {
    const probe = document.createElement('button');
    probe.setAttribute('onclick', 'document.title = "pwned"');
    document.body.append(probe);
    probe.click();
    probe.remove();
    show(document.title === 'pwned' ? 'Inline handler ran: the policy is NOT protecting you' : 'Inline handler did not run');
  } catch (error) {
    show(`Inline handler refused: ${error.name}`);
  }
});

document.querySelector('#raw-html').addEventListener('click', () => {
  try {
    result.innerHTML = untrusted;
  } catch (error) {
    show(`innerHTML refused: ${error.name}`);
  }
});

document.querySelector('#safe-html').addEventListener('click', () => {
  try {
    result.innerHTML = policy ? policy.createHTML(untrusted) : escapeHtml(untrusted);
  } catch (error) {
    show(`Policy refused: ${error.name}`);
  }
});

document.querySelector('#run-eval').addEventListener('click', () => {
  try {
    show(`eval returned ${eval('1 + 1')}`);
  } catch (error) {
    show(`eval refused: ${error.name}`);
  }
});

document.addEventListener('securitypolicyviolation', (event) => {
  console.log(`[csp] ${event.disposition} ${event.violatedDirective} blocked ${event.blockedURI || 'inline'}`);
});
