# frozen_string_literal: true

require_relative "test_helper"

require "nokogiri"
require "sevgi/showcase"

module Sevgi
  EXAMPLES = Test::Suite.new(File.expand_path("#{__dir__}/../srv"))

  class IntegrationTest < Minitest::Test
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
