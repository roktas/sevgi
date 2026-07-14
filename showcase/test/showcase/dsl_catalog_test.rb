# frozen_string_literal: true

require_relative "../test_helper"

require "fileutils"
require "tmpdir"
require "yaml"

module DSLCatalog
  ORDINARY_ELEMENT_METHODS = %w[<< \[\] \[\]= at first has? last].freeze
  DATA = YAML.load_file(File.expand_path("../../doc/data/dsl.yml", __dir__))
  ENTRIES = DATA.fetch("letters").values.flatten.freeze
end

describe "DSL catalog" do
  def catalog_names = DSLCatalog::ENTRIES.map { it.fetch("name") }

  def mixture_modules
    [
      Sevgi::Graphics::Document::Proto,
      Sevgi::Graphics::Document::Base,
      Sevgi::Graphics::Document::Inkscape
    ]
      .flat_map(&:ancestors)
      .grep(Module)
      .select do |mod|
        mod.name&.start_with?("Sevgi::Graphics::Mixtures::")
      end
      .uniq
  end

  def public_dsl_names
    mixture = mixture_modules.flat_map { it.public_instance_methods(false) }.map(&:to_s)
    toplevel = Sevgi::Toplevel.public_instance_methods(false).map(&:to_s)

    (mixture - DSLCatalog::ORDINARY_ELEMENT_METHODS + toplevel + %w[PreRender base sevgi]).uniq.sort
  end

  def prepare(directory)
    File.write(
      File.join(directory, "shape.svg"),
      "<svg xmlns=\"http://www.w3.org/2000/svg\"><g id=\"group\"><rect id=\"mark\" width=\"4\" height=\"2\"/></g></svg>"
    )
    File.write(File.join(directory, "part.sevgi"), "PART_RADIUS = 3\n")
    File.write(
      File.join(directory, "drawing.sevgi"),
      "SVG(:minimal) { rect width: 4, height: 2 }.Save \"drawing.svg\"\n"
    )
  end

  def execute(entry, directory)
    code = entry.fetch("code")
    file = File.join(directory, "catalog.sevgi")

    case entry.fetch("context")
    when "document", "inkscape"
      profile = entry.fetch("context") == "inkscape" ? :inkscape : :default
      document = Sevgi::Graphics.SVG(profile)
      document.instance_eval(code, file, 1)
      document.Render()
    when "script"
      result = Sevgi.execute(code, file:)
      raise result.error if result.error?
    when "rake"
      require "sevgi/binaries/rake"

      receiver = Object.new.extend(FileUtils)
      result = receiver.instance_eval(code, file, 1)
      raise result.error if result.error?
    else
      flunk("Unknown catalog context: #{entry.fetch("context")}")
    end
  end

  it "matches the public DSL surface" do
    assert_equal(public_dsl_names, catalog_names.sort)
  end

  it "has stable unique anchors and complete metadata" do
    anchors = DSLCatalog::ENTRIES.map { it.fetch("anchor") }

    assert_equal(anchors.uniq, anchors)
    assert_empty(DSLCatalog::ENTRIES.reject { it.fetch("summary").match?(/\S/) })
    assert_empty(DSLCatalog::ENTRIES.reject { it.fetch("provider").match?(/\S/) })
    assert_empty(DSLCatalog::ENTRIES.reject { it.fetch("themes").any? })
    assert_empty(DSLCatalog::ENTRIES.reject { it.fetch("code").match?(/\S/) })
  end

  DSLCatalog::ENTRIES.each do |entry|
    it "runs the #{entry.fetch("name")} example" do
      Dir.mktmpdir("sevgi-dsl-") do |directory|
        prepare(directory)
        Dir.chdir(directory) { execute(entry, directory) }
      end
    end
  end
end
