# frozen_string_literal: true

require_relative "test_helper"

require "nokogiri"
require "sevgi/showcase/minitest"

module Sevgi
  EXAMPLES = Showcase.const_get(:Test, false)::Suite.new(File.expand_path("#{__dir__}/../srv"))

  class IntegrationTest < Minitest::Test
    def test_guidesheets_share_visible_bounds
      squared, copperplate = %w[squared copperplate].map do |name|
        Nokogiri::XML(File.read(File.expand_path("../srv/#{name}.svg", __dir__)))
      end

      %w[width height viewBox].each do |attribute|
        assert_equal(squared.root[attribute], copperplate.root[attribute], attribute)
      end

      frames = [squared, copperplate].map { it.at_xpath("//*[@class=\"frame rule\"]") }
      %w[x y width height].each do |attribute|
        assert_equal(frames[0][attribute], frames[1][attribute], attribute)
      end

      paths = copperplate.xpath("//*[@class=\"rule major horizontal\" or @class=\"rule major vertical\"]")
      majors = paths.map { |path| path["d"] }
      [
        "M 0 0 L 0 60",
        "M 0 0 L 90 0",
        "M 0 60 L 90 60",
        "M 90 0 L 90 60"
      ].each { assert_includes(majors, it) }
    end

    def test_all_valid_outputs_are_identical
      EXAMPLES.valids.each do |script|
        result = script.run_passive

        assert_empty(result.err, script.name)
        assert_equal(::File.read(script.svg).chomp, result.to_s, script.name)
      end
    end

    def test_ruler_hline_tick_classes_match_layers
      svg = Nokogiri::XML(File.read(File.expand_path("../srv/ruler.svg", __dir__)))

      refute_empty(svg.xpath("//*[@id=\"halves\"]//*[@class=\"halves\"]"))
      refute_empty(svg.xpath("//*[@id=\"majors\"]//*[@class=\"majors\"]"))
      assert_empty(svg.xpath("//*[@id=\"halves\"]//*[@class=\"minors\"]"))
      assert_empty(svg.xpath("//*[@id=\"majors\"]//*[@class=\"minors\"]"))
    end
  end
end
