# frozen_string_literal: true

module Sevgi
  module Function
    module Color
      def blue(string) = "\e[1m\e[38;5;81m#{string}\e[0m"
      def cyan(string) = "\e[1m\e[38;5;51m#{string}\e[0m"
      def green(string) = "\e[1m\e[38;5;35m#{string}\e[0m"
      def magenta(string) = "\e[1m\e[38;5;200m#{string}\e[0m"
      def red(string) = "\e[1m\e[38;5;197m#{string}\e[0m"
      def yellow(string) = "\e[1m\e[38;5;227m#{string}\e[0m"

      def bold(string) = "\e[1m#{string}\e[0m"
      def dim(string) = "\e[1m\e[2m#{string}\e[0m"
    end

    extend Color
  end
end
