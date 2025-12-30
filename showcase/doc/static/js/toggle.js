// theme.js - save to /js/ folder and load with defer in base.html
(function() {
  var html = document.documentElement;
  
  // Apply saved theme immediately (before DOM ready to prevent flash)
  var saved = localStorage.getItem('theme');
  if (saved) {
    html.setAttribute('data-theme', saved);
  }
  
  // Get effective theme (considering system preference)
  function getEffectiveTheme() {
    var attr = html.getAttribute('data-theme');
    if (attr) return attr;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  
  // Toggle function
  function toggle() {
    var current = getEffectiveTheme();
    var next = current === 'dark' ? 'light' : 'dark';
    
    html.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
  }
  
  // Wait for DOM and attach event
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  function init() {
    var btn = document.querySelector('.theme-toggle');
    if (btn) {
      btn.addEventListener('click', toggle);
    }
  }
})();