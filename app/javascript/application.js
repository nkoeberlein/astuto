// Entry point for the build script in your package.json

// turbolinks
require('turbolinks').start();

// react-rails
var componentRequireContext = require.context('./components', true);
var ReactRailsUJS = require('react_ujs');
ReactRailsUJS.useContext(componentRequireContext);

// bootstrap (js only)
require('bootstrap/js/dist/util');
require('bootstrap/js/dist/dropdown');
require('bootstrap/js/dist/collapse');

// i18n-js translations
require('./translations/index.js.erb');

// Asks before clicks on elements with data-confirm="Question?" go through
// (replaces inline onclick="return confirm(...)", which the CSP blocks)
document.addEventListener('click', (event) => {
  const element = event.target.closest('[data-confirm]');
  if (element && !window.confirm(element.dataset.confirm)) {
    event.preventDefault();
    event.stopImmediatePropagation();
  }
}, true);

// Replaces inline onclick="event.stopPropagation()" handlers, which the
// Content Security Policy blocks: clicks inside these elements don't bubble up
document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll('[data-stop-click-propagation]').forEach((element) => {
    element.addEventListener('click', (event) => event.stopPropagation());
  });
});