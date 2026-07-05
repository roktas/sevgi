# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class RDFTest < Minitest::Test
        def test_license_cc0_renders_rdf_work
          actual = SVG(:inkscape) do
            License_CC0(title: "Demo", creator: "Author")
          end
            .Render(validate: false)

          assert_match(/<rdf:RDF\b/, actual)
          assert_match(%r{<dc:title>Demo</dc:title>}, actual)
          assert_match(%r{<dc:creator>Author</dc:creator>}, actual)
          assert_match(%r{creativecommons.org/publicdomain/zero/1.0/}, actual)
        end

        def test_rdf_requires_block
          error = assert_raises(ArgumentError) do
            SVG(:inkscape) { RDF() }
          end

          assert_match(/\bBlock required\b/, error.message)
        end
      end
    end
  end
end
