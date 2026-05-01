# frozen_string_literal: true

require "tmpdir"
require "hexapdf"

require_relative "../../test_helper"

module Sevgi
  module Sundries
    module Export
      class NativeTest < Minitest::Test
        def test_call_applies_css_before_rendering
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(svg_with_style, output, css: "rect { fill: #ff0000; }")

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 10, 10 ], [ surface.width, surface.height ]
          end
        end

        def test_call_exports_pdf_from_intrinsic_dimensions
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.pdf")

            Export.call(svg(width: 100, height: 100), output)

            assert File.exist?(output)
            assert_operator File.size(output), :>, 0
          end
        end

        def test_call_exports_pdf_with_absolute_units
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.pdf")

            Export.call(a4_svg, output)

            assert_in_delta 595.276, media_box(output).width, 0.001
            assert_in_delta 841.89, media_box(output).height, 0.001
          end
        end

        def test_call_exports_png_with_target_width_and_height
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(svg(width: 100, height: 50), output, width: 20, height: 20)

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 20, 10 ], [ surface.width, surface.height ]
          end
        end

        def test_call_exports_png_with_target_width
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(svg(width: 100, height: 50), output, width: 20)

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 20, 10 ], [ surface.width, surface.height ]
          end
        end

        def test_call_exports_png_with_target_height
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(svg(width: 100, height: 50), output, height: 20)

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 40, 20 ], [ surface.width, surface.height ]
          end
        end

        def test_call_exports_png_with_absolute_units
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(a4_svg, output)

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 794, 1123 ], [ surface.width, surface.height ]
          end
        end

        def test_call_exports_png_with_viewbox_positioning
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(a4_centered_svg, output)

            bbox = raster_bbox(Cairo::ImageSurface.from_png(output))
            assert_in_delta 56, bbox.x, 1
            assert_in_delta 107, bbox.y, 1
            assert_in_delta 682, bbox.width, 1
            assert_in_delta 908, bbox.height, 1
          end
        end

        def test_call_exports_png_with_viewbox_dimensions
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")

            Export.call(svg_with_viewbox, output)

            surface = Cairo::ImageSurface.from_png(output)
            assert_equal [ 100, 50 ], [ surface.width, surface.height ]
          end
        end

        def test_call_rejects_empty_output
          error = assert_raises(ArgumentError) { Export.call(svg(width: 10, height: 10), " ") }

          assert_equal "Export output must be provided", error.message
        end

        def test_call_rejects_invalid_dimensions
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.pdf")
            error  = assert_raises(ExportError) { Export.call(zero_sized_svg, output) }

            assert_equal "Invalid SVG dimensions", error.message
          end
        end

        def test_call_rejects_non_string_svg
          error = assert_raises(ArgumentError) { Export.call(nil, "/tmp/out.pdf") }

          assert_equal "SVG content must be a String", error.message
        end

        def test_call_rejects_unsupported_format
          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.pdf")
            error  = assert_raises(ExportError) { Export.call(svg(width: 10, height: 10), output, format: :webp) }

            assert_equal "Unsupported export format: webp", error.message
          end
        end

        def test_format_for_rejects_missing_extension
          error = assert_raises(ExportError) { Export.format_for!(nil, "out") }

          assert_equal "Unrecognized file extension: ", error.message
        end

        def test_format_for_detects_file_extension
          assert_equal :pdf, Export.format_for!(nil, "out.pdf")
          assert_equal :png, Export.format_for!(nil, "out.png")
        end

        def test_format_for_uses_explicit_format
          assert_equal :png, Export.format_for!("png", "out.pdf")
          assert_equal :pdf, Export.format_for!(:pdf, "out.png")
        end

        def test_format_for_rejects_unrecognized_file_extension
          error = assert_raises(ExportError) { Export.format_for!(nil, "out.webp") }

          assert_equal "Unrecognized file extension: .webp", error.message
        end

        def test_inject_adds_style_before_closing_svg
          assert_equal "<svg><style>rect { fill: red; }</style></svg>", Export.inject("<svg></svg>", "rect { fill: red; }")
        end

        private

          Box = Data.define(:x, :y, :width, :height)

          def a4_svg
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" width="210mm" height="297mm" viewBox="0 0 210 297">
                <rect width="210" height="297" fill="white"/>
              </svg>
            SVG
          end

          def a4_centered_svg
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" width="210mm" height="297mm" viewBox="0 0 210 297">
                <rect x="15" y="28.5" width="180" height="240" fill="black"/>
              </svg>
            SVG
          end

          def media_box(path)
            left, bottom, right, top = HexaPDF::Document.open(path).pages[0].box(:media).value

            Box.new(nil, nil, right - left, top - bottom)
          end

          def raster_bbox(surface)
            min_x = surface.width
            min_y = surface.height
            max_x = -1
            max_y = -1

            surface.data.bytes.each_slice(4).with_index do |(blue, green, red, alpha), index|
              next if alpha.zero? || [ red, green, blue ].all? { it > 250 }

              x = index % surface.width
              y = index / surface.width

              min_x = [ min_x, x ].min
              min_y = [ min_y, y ].min
              max_x = [ max_x, x ].max
              max_y = [ max_y, y ].max
            end

            Box.new(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
          end

          def zero_sized_svg
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" width="0" height="0"></svg>
            SVG
          end

          def svg(width:, height:)
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
                <rect width="#{width}" height="#{height}" fill="white"/>
              </svg>
            SVG
          end

          def svg_with_style
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
                <style>rect { fill: #00ff00; }</style>
                <rect width="10" height="10"/>
              </svg>
            SVG
          end

          def svg_with_viewbox
            <<~SVG
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50">
                <rect width="100" height="50" fill="white"/>
              </svg>
            SVG
          end
      end
    end
  end
end
