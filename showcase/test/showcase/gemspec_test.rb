# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Showcase
    class GemspecTest < Minitest::Test
      def test_gemspec_packages_showcase_sources
        spec = Gem::Specification.load(File.expand_path("../../sevgi-showcase.gemspec", __dir__))

        assert_includes(spec.files, "srv/pacman.sevgi")
        assert_includes(spec.files, "srv/pacman.svg")
        assert_includes(spec.files, "srv/pacman.yml")
      end
    end
  end
end
