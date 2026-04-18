/**
 * Inject a color-scheme switcher dropdown into the Mission Control Jobs
 * navbar and persist the user's choice via cookie.
 *
 * The script element carries two data attributes that parameterise behaviour:
 * - +data-cookie-name+ — cookie key used for persistence
 * - +data-default-color-scheme+ — scheme applied when no cookie is present
 *
 * Selecting +auto+ clears the cookie so the server-side default (typically
 * honouring +prefers-color-scheme+) takes over.
 */
(function() {
  var scriptTag = document.currentScript;
  var COOKIE_NAME = scriptTag && scriptTag.getAttribute('data-cookie-name') || 'mc_jobs_color_scheme';
  var DEFAULT_COLOR_SCHEME = scriptTag && scriptTag.getAttribute('data-default-color-scheme') || 'auto';
  var COOKIE_REGEXP = new RegExp('(?:^|; )' + COOKIE_NAME + '=([^;]*)');

  /**
   * Inline SVG icons keyed by scheme name, rendered inside the dropdown
   * trigger and menu items.
   *
   * @type {Object<string, string>}
   */
  const SCHEME_ICONS = {
    auto: '<svg width="1.25em" height="1.25em" viewBox="0 0 16 16" fill="currentColor">' +
      '<path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zM2 8a6 6 0 0 1 6-6v12a6 6 0 0 1-6-6z"/></svg>',
    light: '<svg width="1.25em" height="1.25em" viewBox="0 0 16 16" fill="currentColor">' +
      '<circle cx="8" cy="8" r="2.5"/>' +
      '<g fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">' +
      '<path d="M8 1v2.5m0 9V15M1 8h2.5m9 0H15M3 3l1.8 1.8M13 3l-1.8 1.8M3 13l1.8-1.8M13 13l-1.8-1.8"/>' +
      '</g></svg>',
    dark: '<svg width="1.25em" height="1.25em" viewBox="0 0 16 16" fill="currentColor">' +
      '<path d="M6 .278a.77.77 0 0 1 .08.858 7.2 7.2 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277' +
      '.527 0 1.04-.055 1.533-.16a.79.79 0 0 1 .81.316.73.73 0 0 1-.031.893A8.35 8.35 0 0 1 8.344 16' +
      'C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.75.75 0 0 1 6 .278zM4.858 1.311A7.27' +
      ' 7.27 0 0 0 1.025 7.71c0 4.02 3.279 7.276 7.319 7.276a7.32 7.32 0 0 0 5.205-2.162c-.337.042' +
      '-.68.063-1.029.063-4.61 0-8.343-3.714-8.343-8.29 0-1.167.242-2.278.681-3.286z"/>' +
      '<path d="M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387' +
      'a.217.217 0 0 1 0 .412l-1.162.387A1.73 1.73 0 0 0 11.593 7.69l-.387 1.162a.217.217 0 0 1-.412' +
      ' 0l-.387-1.162A1.73 1.73 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387c.518' +
      '-.173.924-.579 1.097-1.097l.387-1.162zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386' +
      '.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.16 1.16 0 0 0-.732.732l-.258.774a.145' +
      '.145 0 0 1-.274 0l-.258-.774a1.16 1.16 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774' +
      '-.258c.346-.115.617-.386.732-.732z"/></svg>'
  };

  /**
   * Schemes offered in the dropdown, in presentation order.
   *
   * @type {string[]}
   */
  const SCHEMES = ['auto', 'light', 'dark'];

  /**
   * @param {string} str - Input string
   * @returns {string} +str+ with its first character uppercased
   */
  function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * @returns {string|null} Stored scheme name, or +null+ when no cookie is set
   */
  function getCookieScheme() {
    const match = document.cookie.match(COOKIE_REGEXP);
    return match ? match[1] : null;
  }

  /**
   * Persist a color scheme choice for one year.
   *
   * @param {string} value - Scheme name to persist (+light+ or +dark+)
   * @returns {void}
   */
  function setCookieScheme(value) {
    document.cookie = COOKIE_NAME + '=' + value + '; path=/; max-age=31536000; SameSite=Lax';
  }

  /**
   * Remove the persisted color scheme cookie, reverting to the default.
   *
   * @returns {void}
   */
  function clearCookieScheme() {
    document.cookie = COOKIE_NAME + '=; path=/; max-age=0; SameSite=Lax';
  }

  /**
   * Resolve the active scheme, preferring the cookie over the configured default.
   *
   * @returns {string} Active scheme name (+auto+, +light+, or +dark+)
   */
  function currentMode() {
    return getCookieScheme() || DEFAULT_COLOR_SCHEME;
  }

  /**
   * Persist the requested scheme and reload so the server re-renders with
   * matching stylesheets. No-op when the requested scheme already matches.
   *
   * @param {string} scheme - Target scheme (+auto+, +light+, or +dark+)
   * @returns {void}
   */
  function applyScheme(scheme) {
    if (scheme === currentMode()) return;

    if (scheme === 'auto') {
      clearCookieScheme();
    } else {
      setCookieScheme(scheme);
    }
    location.reload();
  }

  /**
   * Build the switcher dropdown and append it to the navbar.
   *
   * Idempotent — aborts when the navbar is missing or the switcher is already
   * present (e.g. after a Turbo navigation that preserves the element).
   *
   * @returns {void}
   */
  function init() {
    const navbarEnd = document.querySelector('.navbar-end');
    if (!navbarEnd || navbarEnd.querySelector('.mc-scheme-switcher')) return;

    const mode = currentMode();

    const wrapper = document.createElement('div');
    wrapper.className = 'navbar-item has-dropdown is-hoverable mc-scheme-switcher';

    const trigger = document.createElement('a');
    trigger.className = 'navbar-link mc-scheme-trigger';
    trigger.title = capitalize(mode);
    trigger.innerHTML = SCHEME_ICONS[mode];
    wrapper.appendChild(trigger);

    const dropdown = document.createElement('div');
    dropdown.className = 'navbar-dropdown';

    SCHEMES.forEach(function(scheme) {
      const item = document.createElement('a');
      item.className = 'navbar-item';
      item.href = '#';
      item.innerHTML = SCHEME_ICONS[scheme] + ' ' + capitalize(scheme);
      if (scheme === mode) item.classList.add('is-active');

      item.addEventListener('click', function(e) {
        e.preventDefault();
        applyScheme(scheme);
      });

      dropdown.appendChild(item);
    });

    wrapper.appendChild(dropdown);
    navbarEnd.appendChild(wrapper);
  }

  document.addEventListener('turbo:load', init);
})();
