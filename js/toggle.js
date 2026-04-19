// theme.js - save to /js/ folder
(function() {
  var html = document.documentElement;
  var syntaxLight = document.getElementById('syntax-light');
  var syntaxDark = document.getElementById('syntax-dark');

  function updateSyntaxTheme(theme) {
    if (syntaxLight && syntaxDark) {
      if (theme === 'dark') {
        syntaxLight.disabled = true;
        syntaxDark.disabled = false;
      } else {
        syntaxLight.disabled = false;
        syntaxDark.disabled = true;
      }
    }
  }

  var saved = localStorage.getItem('theme');
  if (saved) {
    html.setAttribute('data-theme', saved);
    updateSyntaxTheme(saved);
  } else {
    var systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    updateSyntaxTheme(systemTheme);
  }
  
  function getEffectiveTheme() {
    var attr = html.getAttribute('data-theme');
    if (attr) return attr;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  
  function toggle() {
    var current = getEffectiveTheme();
    var next = current === 'dark' ? 'light' : 'dark';
    
    html.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    updateSyntaxTheme(next);
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  function init() {
    // BURASI DEĞİŞTİ: querySelector yerine querySelectorAll
    // Sayfadaki tüm tema butonlarını (hem mobil hem masaüstü) bulup olay ekliyoruz.
    var btns = document.querySelectorAll('.theme-toggle');
    btns.forEach(function(btn) {
      btn.removeEventListener('click', toggle);
      btn.addEventListener('click', toggle);
    });
  }
})();
