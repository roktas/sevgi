# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Showcase
    class DocAssetsTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)

      def test_local_styles_and_scripts_use_content_hashes
        source = File.read(File.join(ROOT, "doc/templates/base.html"))
        assets = %w[
          css/main.css
          css/normalize.css
          giallo-dark.css
          giallo-light.css
          js/copy.js
          js/menu.js
          js/search.js
          js/tabs.js
          js/toggle.js
        ]

        assets.each do |asset|
          assert_match(/get_url\(path=["']#{Regexp.escape(asset)}["'], cachebust=true\)/, source, asset)
        end
      end

      def test_menu_closes_above_tablet_breakpoint
        source = File.read(File.join(ROOT, "doc/static/js/menu.js"))

        assert_includes(source, "window.innerWidth > 1024")
      end

      def test_mermaid_sources_have_portable_inline_svg
        {
          "derender" => "Derender round trip",
          "validation" => "SVG validation lifecycle"
        }.each do |name, title|
          source = File.read(File.join(ROOT, "doc/data/diagrams/#{name}.mmd"))
          svg = File.read(File.join(ROOT, "doc/data/diagrams/#{name}.svg"))

          assert_includes(source, "@mermaid-js/mermaid-cli 11.16.0", name)
          assert_includes(source, "\nflowchart ", name)
          assert_includes(svg, "<title id=\"chart-title-mermaid-#{name}\">#{title}</title>", name)
          refute_includes(svg, "<foreignObject", name)
          refute_includes(svg, "Syntax error", name)
        end
      end
    end
  end
end
