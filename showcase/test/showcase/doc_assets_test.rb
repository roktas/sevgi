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
    end
  end
end
