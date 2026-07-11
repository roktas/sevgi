# frozen_string_literal: true

require_relative "../test_helper"
require_relative "browser"

module Sevgi
  module Showcase
    class BrowserLifecycleTest < Minitest::Test
      Status = Data.define(:success?)

      class FakeBrowser < Browser
        attr_reader :events

        def initialize(missing: [], responses: [], errors: {})
          super(root: "/showcase/doc")
          @events = []
          @missing = missing
          @ready_error = errors[:ready]
          @responses = responses
          @signal_errors = errors.fetch(:signals, {})
          @wait_error = errors[:wait]
          @reap_error = errors[:reap]
        end

        private

        def executable?(program)
          @events << [:executable, program]
          !@missing.include?(program)
        end

        def free_port
          @events << [:port]
          41_337
        end

        def spawn_server
          @events << [:spawn]
          12_345
        end

        def wait_for_server
          @events << [:ready]
          raise @ready_error if @ready_error
        end

        def capture(*args)
          @events << [:command, *args]
          @responses.shift || ["", "", Status.new(true)]
        end

        def signal_server(signal, server)
          @events << [:signal, signal, server]
          raise @signal_errors.fetch(signal) if @signal_errors.key?(signal)
        end

        def wait_for_exit(server)
          @events << [:wait, server]
          raise @wait_error if @wait_error
        end

        def reap(server)
          @events << [:reap, server]
          raise @reap_error if @reap_error
        end
      end

      def test_start_checks_zola_before_allocating_resources
        browser = FakeBrowser.new(missing: ["zola"])

        error = assert_raises(Browser::Unavailable) { browser.start }

        assert_match(/zola/, error.message)
        assert_equal(
          [[:executable, "zola"], [:executable, "playwright-cli"]],
          browser.events
        )
        assert_nil(browser.port)
        assert_nil(browser.server)
        assert_nil(browser.session)
        refute(browser.opened?)
      end

      def test_start_checks_cli_before_allocating_resources
        browser = FakeBrowser.new(missing: ["playwright-cli"])

        error = assert_raises(Browser::Unavailable) { browser.start }

        assert_match(/playwright-cli/, error.message)
        refute(browser.events.any? { %i[port spawn].include?(it.first) })
        assert_nil(browser.server)
      end

      def test_start_cleans_server_after_ready_timeout
        browser = FakeBrowser.new(errors: {ready: Timeout::Error.new("timed out")})

        assert_raises(Timeout::Error) { browser.start }

        assert_includes(browser.events, [:signal, "TERM", 12_345])
        assert_includes(browser.events, [:wait, 12_345])
        refute(browser.events.any? { it.first == :command })
        assert_nil(browser.server)
        refute(browser.opened?)
      end

      def test_start_cleans_server_after_failed_open
        failure = ["open output", "open failed", Status.new(false)]
        browser = FakeBrowser.new(responses: [failure])

        error = assert_raises(Browser::Error) { browser.start }

        assert_match(/open failed/, error.message)
        assert_equal(1, browser.events.count { it.first == :command })
        assert_includes(browser.events, [:signal, "TERM", 12_345])
        assert_nil(browser.server)
        refute(browser.opened?)
      end

      def test_stop_cleans_server_after_failed_close
        failure = ["close output", "close failed", Status.new(false)]
        browser = FakeBrowser.new(responses: [["", "", Status.new(true)], failure])
        browser.start

        error = assert_raises(Browser::Error) { browser.stop }

        assert_match(/close failed/, error.message)
        assert_includes(browser.events, [:signal, "TERM", 12_345])
        assert_nil(browser.server)
        assert(browser.opened?)
      end

      def test_stop_tolerates_an_already_exited_server
        browser = FakeBrowser.new(
          errors: {
            signals: {"TERM" => Errno::ESRCH.new},
            wait: Errno::ECHILD.new
          }
        )
        browser.start

        browser.stop

        assert_includes(browser.events, [:wait, 12_345])
        assert_nil(browser.server)
        refute(browser.opened?)
      end

      def test_stop_kills_server_after_term_timeout
        browser = FakeBrowser.new(
          errors: {
            signals: {"KILL" => Errno::ESRCH.new},
            wait: Timeout::Error.new("timed out"),
            reap: Errno::ECHILD.new
          }
        )
        browser.start

        browser.stop

        assert_includes(browser.events, [:signal, "TERM", 12_345])
        assert_includes(browser.events, [:signal, "KILL", 12_345])
        assert_includes(browser.events, [:reap, 12_345])
        assert_nil(browser.server)
      end
    end
  end
end
