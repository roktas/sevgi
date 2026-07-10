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
    normalizeSvg(content);
    var shadow =
      container.shadowRoot || (container.attachShadow && container.attachShadow({ mode: 'open' }));

    if (shadow) {
      var style = document.createElement('style');
      style.textContent = [
        ':host{display:flex;align-items:center;justify-content:center;width:100%;height:100%;}',
        'svg{display:block;width:100%;height:100%;max-width:100%;max-height:100%;margin:auto;}'
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

  function normalizeSvg(content) {
    var svg = content.querySelector && content.querySelector('svg');

    if (!svg || svg.getAttribute('viewBox')) return;

    var width = absoluteLength(svg.getAttribute('width'));
    var height = absoluteLength(svg.getAttribute('height'));

    if (width && height) {
      svg.setAttribute('viewBox', '0 0 ' + formatNumber(width) + ' ' + formatNumber(height));
    }
  }

  function absoluteLength(value) {
    var match = String(value || '')
      .trim()
      .match(/^((?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?)(px|pt|pc|mm|cm|in)?$/i);

    if (!match) return null;

    var length = parseFloat(match[1]);
    if (!isFinite(length) || length <= 0) return null;

    return length * unitScale(match[2]);
  }

  function formatNumber(value) {
    return Number(value.toFixed(6)).toString();
  }

  function unitScale(unit) {
    switch ((unit || 'px').toLowerCase()) {
      case 'in':
        return 96;
      case 'cm':
        return 96 / 2.54;
      case 'mm':
        return 96 / 25.4;
      case 'pt':
        return 96 / 72;
      case 'pc':
        return 16;
      default:
        return 1;
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
