// Mobile menu toggle functionality
(function() {
    const toggle = document.querySelector('.mobile-menu-toggle');
    const menu = document.querySelector('.mobile-menu');
    const overlay = document.querySelector('.mobile-menu-overlay');

    if (!toggle || !menu || !overlay) return;

    function openMenu() {
        toggle.setAttribute('aria-expanded', 'true');
        toggle.setAttribute('aria-label', 'Close menu');
        menu.classList.add('active');
        menu.setAttribute('aria-hidden', 'false');
        overlay.classList.add('active');
        overlay.setAttribute('aria-hidden', 'false');
        document.body.classList.add('mobile-menu-open');
        // Move focus to first menu link
        var firstLink = menu.querySelector('a');
        if (firstLink) firstLink.focus();
    }

    function closeMenu() {
        toggle.setAttribute('aria-expanded', 'false');
        toggle.setAttribute('aria-label', 'Open menu');
        menu.classList.remove('active');
        menu.setAttribute('aria-hidden', 'true');
        overlay.classList.remove('active');
        overlay.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('mobile-menu-open');
    }

    function toggleMenu() {
        var isOpen = toggle.getAttribute('aria-expanded') === 'true';
        if (isOpen) {
            closeMenu();
        } else {
            openMenu();
        }
    }

    // Toggle button click
    toggle.addEventListener('click', toggleMenu);

    // Close on overlay click
    overlay.addEventListener('click', closeMenu);

    // Close on escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
            closeMenu();
            toggle.focus();
        }
    });

    // Close menu when clicking a link (using event delegation)
    menu.addEventListener('click', function(e) {
        if (e.target.tagName === 'A') {
            closeMenu();
        }
    });

    // Close menu on window resize if viewport becomes larger
    var resizeTimer;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function() {
            if (window.innerWidth > 768 && toggle.getAttribute('aria-expanded') === 'true') {
                closeMenu();
            }
        }, 100);
    });
})();
