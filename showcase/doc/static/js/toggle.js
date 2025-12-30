// theme.js - save to /js/ folder
(function() {
  var html = document.documentElement;
  var syntaxLight = document.getElementById('syntax-light');
  var syntaxDark = document.getElementById('syntax-dark');

  // Syntax highlighting CSS'lerini güncelleme fonksiyonu
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

  // 1. Kayıtlı temayı hemen uygula (DOM hazır olmadan önce - flash önlemek için)
  var saved = localStorage.getItem('theme');
  if (saved) {
    html.setAttribute('data-theme', saved);
    updateSyntaxTheme(saved);
  } else {
    // Kayıtlı tema yoksa sistem tercihine göre syntax dosyasını ayarla
    // (Bunu yapmazsak varsayılan olarak ikisi de yüklenir ve sonuncusu kazanır)
    var systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    updateSyntaxTheme(systemTheme);
  }
  
  // Efektif temayı bul (sistem tercihi dahil)
  function getEffectiveTheme() {
    var attr = html.getAttribute('data-theme');
    if (attr) return attr;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  
  // Toggle fonksiyonu
  function toggle() {
    var current = getEffectiveTheme();
    var next = current === 'dark' ? 'light' : 'dark';
    
    html.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    
    // Syntax CSS'ini de değiştir
    updateSyntaxTheme(next);
  }
  
  // DOM yüklendikten sonra butonu bağla
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  function init() {
    var btn = document.querySelector('.theme-toggle');
    if (btn) {
      // Olay dinleyicisini eklemeden önce temizle (double-binding önlemi)
      btn.removeEventListener('click', toggle);
      btn.addEventListener('click', toggle);
    }
  }
})();
