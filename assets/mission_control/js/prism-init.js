(function() {
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
