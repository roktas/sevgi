# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Showcase
    class DocA11yTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)
      SMALL_TEXT_CONTRAST = 4.5

      def test_soft_text_tokens_meet_small_text_contrast
        contexts = {
          "default light" => declarations(first_root),
          "system dark" => declarations(system_dark_root),
          "manual dark" => declarations(selector_body("html[data-theme=\"dark\"]")),
          "manual light" => declarations(selector_body("html[data-theme=\"light\"]"))
        }

        contexts.each do |name, values|
          %w[--wt-color-bg --wt-color-bg-soft --wt-color-bg-elevated].each do |background|
            ratio = contrast(values.fetch("--wt-color-text-soft"), values.fetch(background))

            assert_operator(ratio, :>=, SMALL_TEXT_CONTRAST, "#{name} #{background}")
          end
        end
      end

      def test_small_soft_text_consumers_stay_checked
        {
          ".content .footnote-definition" => "0.85rem",
          ".content .footnote-definition-label" => "0.7rem",
          ".nav-outline-link" => "0.84rem"
        }.each do |selector, font_size|
          body = selector_body(selector, css)

          assert_includes(body, "font-size: #{font_size};", selector)
          assert_includes(body, "color: var(--wt-color-text-soft);", selector)
        end
      end

      def test_tabs_shortcode_exposes_named_tab_semantics
        source = read("doc/templates/shortcodes/tabs.html")

        [
          "role=\"tablist\"",
          "aria-label=\"{{ base }} example views\"",
          "role=\"tab\"",
          "aria-selected=\"true\"",
          "aria-selected=\"false\"",
          "aria-controls=\"{{ svg_panel }}\"",
          "aria-controls=\"{{ ruby_panel }}\"",
          "aria-controls=\"{{ xml_panel }}\"",
          "aria-label=\"SVG Output\"",
          "aria-label=\"Ruby Code\"",
          "aria-label=\"XML Code\"",
          "role=\"tabpanel\"",
          "aria-labelledby=\"{{ svg_tab }}\"",
          "aria-labelledby=\"{{ ruby_tab }}\"",
          "aria-labelledby=\"{{ xml_tab }}\"",
          "aria-hidden=\"true\""
        ].each { assert_includes(source, it) }
      end

      private

      def contrast(foreground, background)
        bright, dark = [luminance(foreground), luminance(background)].sort.reverse
        (bright + 0.05) / (dark + 0.05)
      end

      def css = read("doc/static/css/main.css")

      def declarations(body)
        body.scan(/(--wt-color-[\w-]+):\s*(#[0-9a-fA-F]{6})/).to_h
      end

      def first_root
        vars.match(/:root\s*\{(?<body>.*?)\n    \}/m)[:body]
      end

      def hex_channels(color)
        color.delete_prefix("#").scan(/../).map { it.to_i(16) / 255.0 }
      end

      def luminance(color)
        red, green, blue = hex_channels(color).map do |channel|
          channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
        end

        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
      end

      def read(relative) = File.read(File.join(ROOT, relative))

      def selector_body(selector, source = vars)
        source.match(/#{Regexp.escape(selector)}\s*\{(?<body>.*?)\n\s*\}/m)[:body]
      end

      def system_dark_root
        vars.match(/@media \(prefers-color-scheme: dark\)\s*\{\s*:root\s*\{(?<body>.*?)\n        \}\s*\}/m)[:body]
      end

      def vars = read("doc/templates/_vars.html")
    end
  end
end
