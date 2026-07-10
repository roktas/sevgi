# frozen_string_literal: true

require "json"
require "English"
require "open3"
require "socket"
require "timeout"

require_relative "../test_helper"

module Sevgi
  module Showcase
    class DocBrowserTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)
      VIEWPORT = [375, 667].freeze

      def setup
        skip("set BROWSER=1 to run browser checks") unless ENV["BROWSER"] == "1"

        @port = free_port
        @session = "sevgi-browser-#{$PROCESS_ID}"
        @server = Process.spawn(
          "zola",
          "serve",
          "--port",
          @port.to_s,
          chdir: File.join(ROOT, "doc"),
          out: File::NULL,
          err: File::NULL
        )
        wait_for_server
        cli("open", "http://127.0.0.1:#{@port}/showcase/")
      rescue Errno::ENOENT => e
        skip("browser prerequisites unavailable: #{e.message}")
      end

      def teardown
        cli("close") if @session
        return unless @server

        Process.kill("TERM", @server)
        Process.wait(@server)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end

      def test_tabs_support_keyboard_navigation_and_reload
        cli("resize", *VIEWPORT.map(&:to_s))
        assert_tab_state("meter-face", %w[true false false], [false, true, true], nil)

        cli("eval", "() => document.querySelector(\".tabs [role=tab]\").focus()")
        cli("press", "ArrowRight")
        assert_tab_state("meter-face", %w[false true false], [true, false, true], "tab-meter-face-ruby")

        cli("press", "End")
        assert_tab_state("meter-face", %w[false false true], [true, true, false], "tab-meter-face-xml")

        cli("press", "Home")
        assert_tab_state("meter-face", %w[true false false], [false, true, true], "tab-meter-face-svg")

        cli("reload")
        assert_tab_state("meter-face", %w[true false false], [false, true, true], nil)
      end

      def test_mobile_svg_bounds_cover_units_and_artwork_sizes
        cli("resize", *VIEWPORT.map(&:to_s))
        fixtures = eval_json(
          <<~JS
            () => ["meter-face", "checker-board", "snow-flake", "ruler-hline"].map((base) => {
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
        assert_equal("0 0 210 50", fixtures.fetch(3).fetch("viewBox"))

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
        stdout, stderr, status = Open3.capture3("playwright-cli", "-s=#{@session}", *args)
        return stdout if status.success?

        skip("browser prerequisites unavailable: #{stderr}") if stderr.match?(/browser|executable|playwright/i)

        flunk("playwright-cli failed: #{stderr}\n#{stdout}")
      end

      def eval_json(source)
        output = cli("eval", source)
        payload = output.split("### Result\n", 2).fetch(1).split("\n### Ran", 2).first
        JSON.parse(payload)
      end

      def free_port
        server = TCPServer.new("127.0.0.1", 0)
        server.addr.fetch(1)
      ensure
        server&.close
      end

      def wait_for_server
        Timeout.timeout(15) do
          loop do
            TCPSocket.new("127.0.0.1", @port).close
            break
          rescue Errno::ECONNREFUSED
            sleep(0.1)
          end
        end
      end
    end
  end
end
