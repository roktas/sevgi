# frozen_string_literal: true

require "json"

require_relative "../test_helper"
require_relative "browser"

module Sevgi
  module Showcase
    class DocBrowserTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)
      VIEWPORT = [375, 667].freeze

      def setup
        skip("set BROWSER=1 to run browser checks") unless ENV["BROWSER"] == "1"

        @browser = Browser.new(root: File.join(ROOT, "doc"))
        @browser.start
      rescue Browser::Unavailable => e
        skip("browser prerequisites unavailable: #{e.message}")
      end

      def teardown
        @browser&.stop
      rescue Browser::Unavailable => e
        skip("browser prerequisites unavailable: #{e.message}")
      rescue Browser::Error => e
        flunk(e.message)
      end

      def test_tabs_support_keyboard_navigation_and_reload
        cli("resize", *VIEWPORT.map(&:to_s))
        assert_tab_state("meter", %w[true false false], [false, true, true], nil)

        cli(
          "eval",
          "() => document.querySelector('.tabs[data-tab-base=\"meter\"] [role=tab]').focus()"
        )
        cli("press", "ArrowRight")
        assert_tab_state("meter", %w[false true false], [true, false, true], "tab-meter-ruby")

        cli("press", "End")
        assert_tab_state("meter", %w[false false true], [true, true, false], "tab-meter-xml")

        cli("press", "Home")
        assert_tab_state("meter", %w[true false false], [false, true, true], "tab-meter-svg")

        cli("reload")
        assert_tab_state("meter", %w[true false false], [false, true, true], nil)
      end

      def test_mobile_svg_bounds_cover_units_and_artwork_sizes
        cli("resize", *VIEWPORT.map(&:to_s))
        fixtures = eval_json(
          <<~JS
            () => ["meter", "checkers", "snowflake", "ruler"].map((base) => {
              const tab = document.querySelector('.tabs[data-tab-base="' + base + '"]');
              const output = tab.querySelector('.svg-output');
              const svg = output.shadowRoot.querySelector('svg');
              return {
                base,
                viewBox: svg.getAttribute('viewBox'),
                host: output.getBoundingClientRect().toJSON(),
                box: svg.getBoundingClientRect().toJSON()
              };
            })
          JS
        )

        assert_equal("0 0 128 30", fixtures.fetch(0).fetch("viewBox"))
        assert_equal("0 0 900 900", fixtures.fetch(1).fetch("viewBox"))
        assert_equal("-100 -100 200 200", fixtures.fetch(2).fetch("viewBox"))
        assert_equal("0 0 170 30", fixtures.fetch(3).fetch("viewBox"))

        fixtures.each do |fixture|
          host = fixture.fetch("host")
          box = fixture.fetch("box")
          assert_operator(host.fetch("width"), :>, 0, fixture.fetch("base"))
          assert_in_delta(host.fetch("width"), box.fetch("width"), 1, fixture.fetch("base"))
          assert_operator(box.fetch("height"), :>, 0, fixture.fetch("base"))
          assert_operator(box.fetch("height"), :<=, host.fetch("height") + 1, fixture.fetch("base"))
        end

        missing = eval_json(
          <<~JS
            async () => {
              const template = document.createElement('template');
              template.id = 'browser-missing-light';
              template.innerHTML = '<svg><path d="M0 0h1"/></svg>';
              document.body.appendChild(template);
              const output = document.createElement('div');
              output.className = 'svg-output';
              output.dataset.lightTemplate = template.id;
              output.dataset.darkTemplate = template.id;
              document.body.appendChild(output);
              document.documentElement.setAttribute('data-theme', 'light');
              await new Promise((resolve) => setTimeout(resolve, 50));
              const svg = output.shadowRoot && output.shadowRoot.querySelector('svg');
              return { viewBox: svg && svg.getAttribute('viewBox') };
            }
          JS
        )
        assert_nil(missing.fetch("viewBox"))
      end

      def test_mobile_showcase_cards_fit_content
        [375, 320].each do |width|
          cli("resize", width.to_s, VIEWPORT.fetch(1).to_s)
          fixtures = eval_json(
            <<~JS
              () => Array.from(document.querySelectorAll('.showcase-flow > .tabs')).map((card) => {
                const title = card.querySelector('.tabs-title-link');
                const labels = Array.from(card.querySelectorAll(':scope > .label'));
                const panel = card.querySelector('.svg-panel');
                return {
                  base: card.dataset.tabBase,
                  card: card.getBoundingClientRect().toJSON(),
                  panel: panel.getBoundingClientRect().toJSON(),
                  labelTops: labels.map((label) => Math.round(label.getBoundingClientRect().top)),
                  labelWidths: labels.map((label) => label.getBoundingClientRect().width),
                  titleFits: title.scrollWidth <= title.clientWidth
                };
              })
            JS
          )

          fixtures.each do |fixture|
            base = "#{width}px #{fixture.fetch("base")}"
            card = fixture.fetch("card")
            panel = fixture.fetch("panel")
            assert_operator(card.fetch("height"), :<=, 305, base)
            assert_equal(1, fixture.fetch("labelTops").uniq.length, base)
            assert(fixture.fetch("labelWidths").all? { it >= 44 }, base)
            assert(fixture.fetch("titleFits"), base)
            assert_operator(panel.fetch("bottom"), :<=, card.fetch("bottom") + 1, base)
          end
        end
      end

      private

      def assert_tab_state(base, selected, hidden, focused)
        state = eval_json(
          <<~JS
            () => {
              const tab = document.querySelector('.tabs[data-tab-base="#{base}"]');
              return {
                selected: Array.from(tab.querySelectorAll('[role=tab]')).map((node) => node.getAttribute('aria-selected')),
                hidden: Array.from(tab.querySelectorAll('[role=tabpanel]')).map((node) => node.hidden),
                focused: document.activeElement && document.activeElement.id
              };
            }
          JS
        )
        assert_equal(selected, state.fetch("selected"), base)
        assert_equal(hidden, state.fetch("hidden"), base)
        assert_equal(focused, state.fetch("focused"), base) unless focused.nil?
      end

      def cli(*args)
        @browser.command(*args)
      rescue Browser::Unavailable => e
        skip("browser prerequisites unavailable: #{e.message}")
      rescue Browser::Error => e
        flunk(e.message)
      end

      def eval_json(source)
        output = cli("eval", source)
        payload = output.split("### Result\n", 2).fetch(1).split("\n### Ran", 2).first
        JSON.parse(payload)
      end

    end
  end
end
