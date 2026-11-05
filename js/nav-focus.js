document.addEventListener('DOMContentLoaded', () => {
  const header = document.getElementById('quarto-header');
  if (!header) return;

  // Listen for focus entering any element inside the header (including Shift+Tab backwards)
  header.addEventListener('focusin', () => {
    header.classList.remove('headroom--unpinned');
    header.classList.add('headroom--pinned');
  });

  // Optional: If you want it to unpin when focus leaves the header entirely
  header.addEventListener('focusout', (event) => {
    // Check if the newly focused element is outside the header
    if (!header.contains(event.relatedTarget)) {
      header.classList.remove('headroom--pinned');
      header.classList.add('headroom--unpinned');
    }
  });
});
