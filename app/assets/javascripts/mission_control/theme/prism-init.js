/**
 * Initialise Prism.js syntax highlighting for JSON payloads rendered by
 * Mission Control Jobs.
 *
 * Runs on every +turbo:load+ event and upgrades +<pre>+ blocks whose content
 * starts with +{+ or +[+ to highlighted JSON.
 */
(function() {
  /**
   * Highlight JSON-looking +<pre>+ blocks in the current document.
   *
   * No-op when Prism or the JSON grammar is not loaded yet. Idempotent — skips
   * elements already tagged with the +language-json+ class.
   *
   * @returns {void}
   */
  function highlightJson() {
    if (typeof Prism === 'undefined' || !Prism.languages.json) return;
    document.querySelectorAll('pre:not(.language-json)').forEach(function(pre) {
      const text = pre.textContent.trim();
      if (text.charAt(0) === '{' || text.charAt(0) === '[') {
        pre.innerHTML = Prism.highlight(pre.textContent, Prism.languages.json, 'json');
        pre.classList.add('language-json');
      }
    });
  }

  document.addEventListener('turbo:load', highlightJson);
})();
