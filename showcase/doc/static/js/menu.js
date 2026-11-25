(function () {
  const toggle = document.querySelector(".mobile-menu-toggle");
  const menu = document.querySelector(".mobile-menu");
  const overlay = document.querySelector(".mobile-menu-overlay");

  if (!toggle || !menu || !overlay) return;

  const search = document.querySelector(".search-container");
  const searchHome = search.parentElement;
  const menuContent = menu.querySelector(".mobile-menu-content");
  const background = document.querySelectorAll("header > :not(.mobile-menu-toggle), .hero, main, footer");
  const mobile = window.matchMedia("(max-width: 1024px)");

  function openMenu() {
    toggle.setAttribute("aria-expanded", "true");
    toggle.setAttribute("aria-label", "Close menu");
    menu.classList.add("active");
    menu.setAttribute("aria-hidden", "false");
    overlay.classList.add("active");
    document.body.classList.add("mobile-menu-open");
    background.forEach((element) => { element.inert = true; });
    menu.querySelector("input").focus();
  }

  function closeMenu(restoreFocus = true) {
    if (restoreFocus) toggle.focus();
    toggle.setAttribute("aria-expanded", "false");
    toggle.setAttribute("aria-label", "Open menu");
    menu.classList.remove("active");
    menu.setAttribute("aria-hidden", "true");
    overlay.classList.remove("active");
    document.body.classList.remove("mobile-menu-open");
    background.forEach((element) => { element.inert = false; });
  }

  function placeSearch() {
    if (mobile.matches) {
      menuContent.prepend(search);
    } else {
      closeMenu(false);
      searchHome.prepend(search);
    }
  }

  function toggleMenu() {
    var isOpen = toggle.getAttribute("aria-expanded") === "true";
    if (isOpen) {
      closeMenu();
    } else {
      openMenu();
    }
  }

  toggle.addEventListener("click", toggleMenu);
  overlay.addEventListener("click", () => closeMenu());

  document.addEventListener("keydown", function (e) {
    if (toggle.getAttribute("aria-expanded") !== "true") return;
    if (e.key === "Escape") {
      closeMenu();
    } else if (e.key === "Tab") {
      const items = Array.from(menu.querySelectorAll("input, a[href], summary"));
      const last = items.findLast((element) => element.checkVisibility());
      if (e.shiftKey && document.activeElement === toggle) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        toggle.focus();
      }
    }
  });

  menu.addEventListener("click", function (e) {
    if (e.target.closest("a") && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
      closeMenu();
    }
  });

  mobile.addEventListener("change", placeSearch);
  placeSearch();
})();
