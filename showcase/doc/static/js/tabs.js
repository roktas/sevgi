(function() {
  var root = document.documentElement;
  var systemDark = window.matchMedia('(prefers-color-scheme: dark)');

  function getTheme() {
    return root.getAttribute('data-theme') || (systemDark.matches ? 'dark' : 'light');
  }

  function render(container) {
    var templateId =
      getTheme() === 'dark' ? container.dataset.darkTemplate : container.dataset.lightTemplate;
    var template = templateId && document.getElementById(templateId);

    if (!template || container.dataset.currentTemplate === templateId) return;

    var content = template.content.cloneNode(true);
    var shadow =
      container.shadowRoot || (container.attachShadow && container.attachShadow({ mode: 'open' }));

    if (shadow) {
      var style = document.createElement('style');
      style.textContent = [
        ':host{display:flex;align-items:center;justify-content:center;width:100%;height:100%;}',
        'svg{display:block;max-width:100%;max-height:100%;width:auto;height:auto;margin:auto;}'
      ].join('');
      replace(shadow, style, content);
    } else {
      replace(container, content);
    }

    container.dataset.currentTemplate = templateId;
  }

  function replace(node) {
    while (node.firstChild) node.removeChild(node.firstChild);

    for (var i = 1; i < arguments.length; i++) {
      node.appendChild(arguments[i]);
    }
  }

  function renderAll() {
    var outputs = document.querySelectorAll('.svg-output[data-light-template][data-dark-template]');
    Array.prototype.forEach.call(outputs, render);
  }

  function init() {
    renderAll();

    new MutationObserver(renderAll).observe(root, {
      attributes: true,
      attributeFilter: ['data-theme']
    });

    if (systemDark.addEventListener) {
      systemDark.addEventListener('change', renderAll);
    } else if (systemDark.addListener) {
      systemDark.addListener(renderAll);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
