# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Sundries
    class ExportTest < Minitest::Test
      def test_export_exposes_only_directional_format_lookup
        assert_equal({pdf: ".pdf", png: ".png"}, Export::AVAILABLE)
        assert_raises(NameError) { Export::EXTENSIONS }
      end
    end
  end
end
