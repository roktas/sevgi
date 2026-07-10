# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Showcase
    class PassiveTest < Minitest::Test
      def test_save_redirects_output
        base = Graphics::Document::Base
        save = base.instance_method(:Save)

        require "sevgi/showcase/passive"

        doc = SVG do
          rect(width: 1, height: 1)
        end

        out, = capture_io { doc.Save() }

        assert_includes(out, "<rect")
      ensure
        base.remove_method(:Save) if base.method_defined?(:Save) && base.instance_method(:Save).owner == base
        base.define_method(:Save, save) if save
        base.remove_method(:Save!) if base.method_defined?(:Save!) && base.instance_method(:Save!).owner == base
      end
    end
  end
end
