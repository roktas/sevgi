# frozen_string_literal: true

module Sevgi
  module Function
    # ANSI color and style helpers for terminal output.
    module Color
      # Wraps a string in the blue terminal style.
      # @param string [Object] content to style
      # @return [String]
      def blue(string) = "\e[1m\e[38;5;81m#{string}\e[0m"

      # Wraps a string in the cyan terminal style.
      # @param string [Object] content to style
      # @return [String]
      def cyan(string) = "\e[1m\e[38;5;51m#{string}\e[0m"

      # Wraps a string in the green terminal style.
      # @param string [Object] content to style
      # @return [String]
      def green(string) = "\e[1m\e[38;5;35m#{string}\e[0m"

      # Wraps a string in the magenta terminal style.
      # @param string [Object] content to style
      # @return [String]
      def magenta(string) = "\e[1m\e[38;5;200m#{string}\e[0m"

      # Wraps a string in the red terminal style.
      # @param string [Object] content to style
      # @return [String]
      def red(string) = "\e[1m\e[38;5;197m#{string}\e[0m"

      # Wraps a string in the yellow terminal style.
      # @param string [Object] content to style
      # @return [String]
      def yellow(string) = "\e[1m\e[38;5;227m#{string}\e[0m"

      # Wraps a string in the bold terminal style.
      # @param string [Object] content to style
      # @return [String]
      def bold(string) = "\e[1m#{string}\e[0m"

      # Wraps a string in the dim terminal style.
      # @param string [Object] content to style
      # @return [String]
      def dim(string) = "\e[1m\e[2m#{string}\e[0m"
    end

    extend Color
  end
end
