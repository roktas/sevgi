# frozen_string_literal: true

require_relative "test_helper"
require "sevgi"
require "nokogiri"
require "open3"
require "rbconfig"
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
          if name == "dsl" && index == 1
            result = Sevgi.execute(example(name, index), file: "recipe.sevgi")
            raise result.error if result.error?
          else
            run_library(example(name, index))
          end

          xml = Nokogiri::XML(File.read(output), &:strict)
          assert_equal("http://www.w3.org/2000/svg", xml.root.namespace.href)
          assert_operator(xml.root["width"].to_f, :>, 0)
          assert_equal(1, xml.xpath("//*[local-name()='#{shape}']").size)
        end
      end
    end
  end

  def test_library_recipes_render_expected_attributes
    [
      ["layout", 0, "rect", "transform", "translate(19 10)"],
      ["ruby", 2, "text", "class", "badge"],
      ["derender", 1, "circle", "r", "4"]
    ].each do |name, index, shape, attribute, expected|
      output = run_library("puts begin\n#{example(name, index)}\nend")
      xml = Nokogiri::XML(output, &:strict)
      assert_equal(expected, xml.at_xpath("//*[local-name()='#{shape}']")[attribute])
    end
  end

  def test_pdf_recipes
    2.times do |index|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          run_library(example("output", index))
          assert_equal("%PDF-", File.binread("badge.pdf", 5))
        end
      end
    end
  end

  def test_include_recipe_preserves_internal_references
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(
          "brand.svg",
          <<~SVG
            <svg xmlns="http://www.w3.org/2000/svg">
              <g id="logo" transform="translate(2 3)">
                <defs><path id="mark" d="M 0 0 L 4 4"/></defs>
                <use href="#mark"/>
              </g>
            </svg>
          SVG
        )
        run_library(example("derender", 0))
        xml = Nokogiri::XML(File.read("badge.svg"), &:strict)
        assert_equal("translate(2 3)", xml.at_css("g#logo")["transform"])
        assert_equal("mark", xml.at_css("defs path")["id"])
        assert_equal("#mark", xml.at_css("use")["href"])
      end
    end
  end

  private

  def run_library(source)
    output, error, status = Open3.capture3(RbConfig.ruby, "-rsevgi", "-e", source)
    assert_predicate(status, :success?, error)
    assert_empty(error)
    output
  end

  def example(name, index)
    File.read(File.join(ROOT, "references", "#{name}.md")).scan(/^```ruby\n(.*?)^```$/m).fetch(index).first
  end
end
