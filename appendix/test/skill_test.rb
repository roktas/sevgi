# frozen_string_literal: true

require_relative "test_helper"
require "sevgi"
require "nokogiri"
require "tmpdir"

class SkillTest < Minitest::Test
  ROOT = File.expand_path("../agents/skills/sevgi", __dir__)

  def test_local_references_exist
    Dir[File.join(ROOT, "**/*.md")].each do |file|
      File.read(file).scan(/\]\(([^)]+)\)/).flatten.each do |link|
        next if link.match?(%r{\A(?:https?://|#)})

        assert_path_exists(File.expand_path(link.split("#").first, File.dirname(file)), "#{file}: #{link}")
      end
    end
  end

  def test_complete_saved_svg_recipes
    [["dsl", 1, "badge.svg", "circle"], ["dsl", 2, "badge.svg", "circle"], ["ruby", 1, "mark.svg", "rect"]].each do |
        name,
        index,
        output,
        shape
      |
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          result = Sevgi.execute(example(name, index), file: "recipe.sevgi")
          raise result.error if result.error?
          xml = Nokogiri::XML(File.read(output), &:strict)
          assert_equal("http://www.w3.org/2000/svg", xml.root.namespace.href)
          assert_operator(xml.root["width"].to_f, :>, 0)
          assert_equal(1, xml.xpath("//*[local-name()='#{shape}']").size)
        end
      end
    end
  end

  def test_positioned_alignment_recipe
    result = Sevgi.execute(example("layout", 0), file: "alignment.sevgi")
    raise result.error if result.error?
    xml = Nokogiri::XML(result.value, &:strict)
    assert_equal("translate(19 10)", xml.at_xpath("//*[local-name()='rect']")["transform"])
  end

  def test_pdf_recipes
    2.times do |index|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          result = Sevgi.execute(example("output", index), file: "recipe.sevgi")
          raise result.error if result.error?
          assert_equal("%PDF-", File.binread("badge.pdf", 5))
        end
      end
    end
  end

  private

  def example(name, index)
    File.read(File.join(ROOT, "references", "#{name}.md")).scan(/^```ruby\n(.*?)^```$/m).fetch(index).first
  end
end
