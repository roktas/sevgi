# frozen_string_literal: true

require "English"
require "open3"
require "socket"
require "timeout"

module Sevgi
  module Showcase
    class Browser
      PROGRAMS = %w[zola playwright-cli].freeze
      START_TIMEOUT = 15
      STOP_TIMEOUT = 5

      class Error < StandardError
      end

      class Unavailable < Error
      end

      attr_reader :port, :server, :session

      def initialize(root:)
        @root = root
        @opened = false
      end

      def start
        check_prerequisites
        @port = free_port
        @session = "sevgi-browser-#{$PROCESS_ID}-#{@port}"
        @server = spawn_server
        wait_for_server
        command("open", "http://127.0.0.1:#{@port}/showcase/")
        @opened = true
        self
      rescue StandardError
        stop_server
        raise
      end

      def stop
        close_browser
      ensure
        stop_server
      end

      def opened? = @opened

      def command(*args)
        stdout, stderr, status = capture("playwright-cli", "-s=#{@session}", *args)
        return stdout if status.success?

        error = prerequisite_error?(stderr) ? Unavailable : Error
        raise error, ["playwright-cli failed: #{args.join(" ")}", stderr, stdout].reject(&:empty?).join("\n")
      rescue Errno::ENOENT => e
        raise Unavailable, "browser prerequisite unavailable: #{e.message}"
      end

      private

      def check_prerequisites
        missing = PROGRAMS.reject { executable?(it) }
        return if missing.empty?

        raise Unavailable, "missing browser prerequisites: #{missing.join(", ")}"
      end

      def executable?(program) = Sevgi::F.executable?(program)

      def free_port
        listener = TCPServer.new("127.0.0.1", 0)
        listener.addr.fetch(1)
      ensure
        listener&.close
      end

      def spawn_server
        Process.spawn(
          "zola",
          "serve",
          "--port",
          @port.to_s,
          chdir: @root,
          out: File::NULL,
          err: File::NULL
        )
      end

      def wait_for_server
        Timeout.timeout(START_TIMEOUT) do
          loop do
            TCPSocket.new("127.0.0.1", @port).close
            break
          rescue Errno::ECONNREFUSED
            sleep(0.1)
          end
        end
      end

      def close_browser
        return unless @opened

        command("close")
        @opened = false
      end

      def stop_server
        server = @server
        return unless server

        signal_server("TERM", server)
      rescue Errno::ESRCH
        nil
      ensure
        reap_server(server) if server
        @server = nil
      end

      def reap_server(server)
        wait_for_exit(server)
      rescue Errno::ECHILD
        nil
      rescue Timeout::Error
        kill_server(server)
      end

      def kill_server(server)
        signal_server("KILL", server)
      rescue Errno::ESRCH
        nil
      ensure
        reap_after_kill(server)
      end

      def reap_after_kill(server)
        reap(server)
      rescue Errno::ECHILD
        nil
      end

      def signal_server(signal, server) = Process.kill(signal, server)

      def wait_for_exit(server)
        Timeout.timeout(STOP_TIMEOUT) { reap(server) }
      end

      def reap(server) = Process.wait(server)

      def capture(*args) = Open3.capture3(*args)

      def prerequisite_error?(stderr)
        stderr.match?(
          /(?:browser|executable).*(?:install|missing|not found|does not exist)|(?:install|missing).*(?:browser|executable)/i
        )
      end
    end
  end
end
