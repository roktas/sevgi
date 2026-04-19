// Search functionality adapted from Adidoks theme
// Uses Zola's built-in elasticlunr search index

var suggestions = document.getElementById('suggestions');
var userinput = document.getElementById('userinput');

// Focus search on '/' key, blur on Escape
document.addEventListener('keydown', function(e) {
  if (e.key === '/' && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA') {
    e.preventDefault();
    userinput.focus();
  }
  if (e.key === 'Escape') {
    userinput.blur();
    suggestions.style.display = 'none';
  }
});

// Hide suggestions when clicking outside
document.addEventListener('click', function(event) {
  if (!suggestions.contains(event.target) && event.target !== userinput) {
    suggestions.style.display = 'none';
  }
});

// Arrow key navigation through results
document.addEventListener('keydown', function(e) {
  const focusable = suggestions.querySelectorAll('a');
  if (suggestions.style.display === 'none' || focusable.length === 0) return;

  const index = Array.from(focusable).indexOf(document.activeElement);

  if (e.key === 'ArrowUp') {
    e.preventDefault();
    const nextIndex = index > 0 ? index - 1 : 0;
    focusable[nextIndex].focus();
  } else if (e.key === 'ArrowDown') {
    e.preventDefault();
    const nextIndex = index + 1 < focusable.length ? index + 1 : index;
    focusable[nextIndex].focus();
  }
});

// Main search functionality
(function() {
  var index = elasticlunr.Index.load(window.searchIndex);

  userinput.addEventListener('input', function() {
    var value = this.value.trim();

    if (!value) {
      suggestions.style.display = 'none';
      suggestions.innerHTML = '';
      return;
    }

    var results = index.search(value, {
      bool: "OR",
      fields: {
        title: { boost: 2 },
        body: { boost: 1 }
      }
    });

    var items = value.split(/\s+/);
    suggestions.innerHTML = '';

    if (results.length === 0) {
      suggestions.style.display = 'none';
      return;
    }

    suggestions.style.display = 'block';

    results.slice(0, 8).forEach(function(page) {
      if (page.doc.body !== '') {
        var entry = document.createElement('a');
        entry.href = page.ref;
        entry.className = 'search-result';
        entry.innerHTML = '<span class="search-title">' + escapeHtml(page.doc.title) + '</span>' +
                         '<span class="search-excerpt">' + makeTeaser(page.doc.body, items) + '</span>';
        suggestions.appendChild(entry);
      }
    });
  });

  // Only hide suggestions on modifier-click (opens in new tab).
  // Normal clicks navigate away, so the page resets naturally.
  // Clearing during navigation causes layout shift during the view transition.
  suggestions.addEventListener('click', function(e) {
    if (e.ctrlKey || e.metaKey || e.shiftKey) {
      suggestions.innerHTML = '';
      suggestions.style.display = 'none';
    }
  });

  function escapeHtml(text) {
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Generate search excerpt with highlighted terms (adapted from mdbook/Adidoks)
  function makeTeaser(body, terms) {
    var TERM_WEIGHT = 40;
    var NORMAL_WORD_WEIGHT = 2;
    var FIRST_WORD_WEIGHT = 8;
    var TEASER_MAX_WORDS = 30;

    var stemmedTerms = terms.map(function(w) {
      return elasticlunr.stemmer(w.toLowerCase());
    });
    var termFound = false;
    var index = 0;
    var weighted = [];

    var sentences = body.toLowerCase().split(". ");
    for (var i in sentences) {
      var words = sentences[i].split(/[\s\n]/);
      var value = FIRST_WORD_WEIGHT;
      for (var j in words) {
        var word = words[j];
        if (word.length > 0) {
          for (var k in stemmedTerms) {
            if (elasticlunr.stemmer(word).startsWith(stemmedTerms[k])) {
              value = TERM_WEIGHT;
              termFound = true;
            }
          }
          weighted.push([word, value, index]);
          value = NORMAL_WORD_WEIGHT;
        }
        index += word.length + 1;
      }
      index += 1;
    }

    if (weighted.length === 0) {
      return body.length > TEASER_MAX_WORDS * 10
        ? escapeHtml(body.substring(0, TEASER_MAX_WORDS * 10)) + '...'
        : escapeHtml(body);
    }

    var windowSize = Math.min(weighted.length, TEASER_MAX_WORDS);
    var windowWeights = [];
    var curSum = 0;

    for (var i = 0; i < windowSize; i++) {
      curSum += weighted[i][1];
    }
    windowWeights.push(curSum);

    for (var i = 0; i < weighted.length - windowSize; i++) {
      curSum -= weighted[i][1];
      curSum += weighted[i + windowSize][1];
      windowWeights.push(curSum);
    }

    var maxSumIndex = 0;
    if (termFound) {
      var maxFound = 0;
      for (var i = windowWeights.length - 1; i >= 0; i--) {
        if (windowWeights[i] > maxFound) {
          maxFound = windowWeights[i];
          maxSumIndex = i;
        }
      }
    }

    var teaser = [];
    var startIndex = weighted[maxSumIndex][2];

    for (var i = maxSumIndex; i < maxSumIndex + windowSize; i++) {
      var word = weighted[i];
      if (startIndex < word[2]) {
        teaser.push(escapeHtml(body.substring(startIndex, word[2])));
        startIndex = word[2];
      }

      if (word[1] === TERM_WEIGHT) {
        teaser.push('<b>');
      }

      startIndex = word[2] + word[0].length;
      teaser.push(escapeHtml(body.substring(word[2], startIndex)));

      if (word[1] === TERM_WEIGHT) {
        teaser.push('</b>');
      }
    }
    teaser.push('...');
    return teaser.join('');
  }
})();
