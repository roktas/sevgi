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

      def test_dsl_metadata_labels_are_unique
        cli("goto", "http://127.0.0.1:#{@browser.port}/dsl/")
        duplicates = eval_json(
          <<~JS
            () => Array.from(document.querySelectorAll('.dsl-entry')).filter((entry) => {
              const labels = Array.from(entry.querySelectorAll('.dsl-meta > *'), (label) =>
                label.textContent.trim().toLowerCase()
              );
              return new Set(labels).size !== labels.length;
            }).map((entry) => entry.querySelector('.dsl-word').textContent.trim())
          JS
        )

        assert_empty(duplicates)
      end

      def test_code_blocks_preserve_source_and_highlighting
        cli("resize", "1440", "1000")
        cli("goto", "http://127.0.0.1:#{@browser.port}/start/")
        %w[light dark].each do |theme|
          cli("eval", "() => localStorage.setItem('theme', '#{theme}')")
          cli("reload")
          blocks = eval_json(
            <<~JS
              () => Array.from(document.querySelectorAll('.content pre code')).map((code) => ({
                language: code.dataset.lang,
                colors: new Set(Array.from(code.querySelectorAll('span'), (span) =>
                  getComputedStyle(span).color
                )).size,
                markup: code.querySelectorAll('svg, a, pre').length
              }))
            JS
          )
          blocks.each do |block|
            label = "start #{theme} #{block.fetch("language", "plain")}"
            assert_equal(0, block.fetch("markup"), label)
            next unless %w[ruby xml bash sh].include?(block["language"])

            assert_operator(block.fetch("colors"), :>, 1, label)
          end
        end

        cli("goto", "http://127.0.0.1:#{@browser.port}/examples/")
        sources = eval_json(
          <<~JS
            () => Array.from(document.querySelectorAll('.tabs .code-panel')).flatMap((panel) =>
              ['light', 'dark'].map((theme) => ({
                base: panel.closest('.tabs').dataset.tabBase,
                theme,
                extension: panel.classList.contains('ruby-panel') ? 'sevgi' : 'svg',
                source: panel.querySelector('.theme-' + theme + ' pre code')?.textContent
              }))
            )
          JS
        )
        assert_operator(sources.size, :>=, 72)
        pokey = sources.find { |source| source.values_at("base", "theme", "extension") == %w[pokey light sevgi] }
        assert_equal(
          <<~RUBY
            SVG :default, width: 100, height: 100 do
              rect x: 0, y: 0, width: 100, height: 100, fill: "white"
              path fill: "purple", d: %w[
                M10 101 V50 A40 40 0 0 1 90 50 V101
                L76 85 L63 101 L50 85 L37 101 L24 85 Z
              ]

              [25, 50].each do |x|
                circle cx: x, cy: 40, r: 8, fill: "white"
              end
            end.Save
          RUBY
            .rstrip,
          pokey.fetch("source").rstrip
        )
        sources.each do |source|
          path = "doc/showcase/#{source.fetch("theme")}/#{source.fetch("base")}.#{source.fetch("extension")}"
          expected = File.read(File.join(ROOT, path))
          if source.fetch("extension") == "sevgi"
            expected = expected.delete_prefix("#!/usr/bin/env -S ruby -S sevgi\n# frozen_string_literal: true\n").lstrip
          end

          assert_equal(expected.rstrip, source.fetch("source").to_s.rstrip, path)
        end
      end

      def test_dsl_task_links_and_examples_render_as_html
        cli("resize", *VIEWPORT.map(&:to_s))
        cli("goto", "http://127.0.0.1:#{@browser.port}/dsl/#theme-script-tools")
        state = eval_json(
          <<~JS
            () => ({
              links: Array.from(document.querySelectorAll('.dsl-links a')).every((link) =>
                link.querySelector('code') && document.getElementById(link.hash.slice(1))
              ),
              count: document.querySelectorAll('.dsl-links a').length,
              entries: Array.from(document.querySelectorAll('.dsl-entry')).every((entry) =>
                entry.querySelector('.dsl-meta > span') && entry.querySelector('pre code[data-lang="ruby"]')
              ),
              inlineCode: Array.from(document.querySelectorAll('.dsl-theme-intro p, .dsl-entry > p'))
                .filter((text) => text.textContent.includes('.sevgi'))
                .map((text) => Boolean(text.querySelector('code'))),
              raw: document.querySelectorAll('.dsl-themes pre, .dsl-entry pre code[data-lang="plain"]').length,
              rawMarkdown: Array.from(document.querySelectorAll('.dsl-theme-intro p, .dsl-entry > p')).filter((text) =>
                text.textContent.includes('`')
              ).length,
              themeVisible: document.querySelector('#theme-script-tools').getBoundingClientRect().top >=
                document.querySelector('header').getBoundingClientRect().bottom,
              trailing: Array.from(document.querySelectorAll('.dsl-entry pre code')).filter((code) => {
                const line = code.lastElementChild;
                return line && !line.textContent && getComputedStyle(line).display !== 'none';
              }).length
            })
          JS
        )
        assert_operator(state.fetch("count"), :>, 0)
        assert(state.fetch("links"))
        assert(state.fetch("entries"))
        assert_operator(state.fetch("inlineCode").size, :>, 0)
        assert(state.fetch("inlineCode").all?)
        assert_equal(0, state.fetch("raw"))
        assert_equal(0, state.fetch("rawMarkdown"))
        assert(state.fetch("themeVisible"))
        assert_equal(0, state.fetch("trailing"))
      end

      def test_example_index_toggles_and_links_to_every_card
        state = eval_json(
          <<~JS
            () => ({
              open: document.querySelector('.example-index').open,
              links: Array.from(document.querySelectorAll('.example-index a'), (link) => link.hash.slice(1)),
              cards: Array.from(document.querySelectorAll('.showcase-flow > .tabs'), (card) => card.id)
            })
          JS
        )
        refute(state.fetch("open"))
        assert_equal(state.fetch("cards"), state.fetch("links"))
        cli("eval", "() => document.querySelector('.example-index > summary').focus()")
        cli("press", "Enter")
        assert(eval_json("() => document.querySelector('.example-index').open"))
        cli("press", "Enter")
        refute(eval_json("() => document.querySelector('.example-index').open"))
        %w[light dark].each do |theme|
          cli("eval", "() => document.documentElement.setAttribute('data-theme', '#{theme}')")
          svg = eval_json(
            <<~JS
              async () => {
                const link = document.querySelector('[data-svg-view="protractor"]');
                const source = await (await fetch(link.href)).text();
                const xml = new DOMParser().parseFromString(source, 'image/svg+xml');
                const image = new Image();
                image.src = link.href;
                await image.decode();
                return {
                  namespace: xml.documentElement.namespaceURI,
                  labels: xml.querySelectorAll('text').length,
                  width: image.naturalWidth,
                  source,
                expected: new XMLSerializer().serializeToString(document.querySelector('#svg-light-protractor').content.querySelector('svg'))
                };
              }
            JS
          )
          assert_equal("http://www.w3.org/2000/svg", svg.fetch("namespace"))
          assert_operator(svg.fetch("labels"), :>, 10)
          assert_operator(svg.fetch("width"), :>, 0)
          assert_equal(svg.fetch("expected"), svg.fetch("source"))
        end
      end

      def test_mermaid_diagrams_are_inline
        %w[derender documents].each do |page|
          cli("goto", "http://127.0.0.1:#{@browser.port}/#{page}/")
          state = eval_json(
            <<~JS
              () => {
                const diagram = document.querySelector('.mermaid');
                const svg = diagram && diagram.querySelector('svg');
                return {
                  diagrams: document.querySelectorAll('.mermaid').length,
                  rendered: document.querySelectorAll('.mermaid svg').length,
                  width: svg ? svg.getBoundingClientRect().width : 0,
                  scripts: document.querySelectorAll('script[src*="mermaid"]').length,
                  foreignObjects: document.querySelectorAll('.mermaid foreignObject').length,
                  syntaxErrors: Array.from(document.querySelectorAll('.mermaid text')).filter((node) =>
                    node.textContent.includes('Syntax error')
                  ).length
                };
              }
            JS
          )

          assert_equal(1, state.fetch("diagrams"), page)
          assert_equal(1, state.fetch("rendered"), page)
          assert_operator(state.fetch("width"), :>, 0, page)
          assert_equal(0, state.fetch("scripts"), page)
          assert_equal(0, state.fetch("foreignObjects"), page)
          assert_equal(0, state.fetch("syntaxErrors"), page)
        end
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

          assert_operator(fixtures.size, :>=, 18)
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
