# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class DocumentationTest < Minitest::Test
    ROOT = ::File.expand_path("../..", __dir__)
    LIB_FILES = %w[
      function
      geometry
      graphics
      standard
      derender
      sundries
      toplevel
      showcase
    ]
      .flat_map { ::Dir[::File.join(ROOT, it, "lib/**/*.rb")] }
      .freeze
    CONTRACTS = {
      "Sevgi::Derender.evaluate" => {
        params: %w[content element id],
        returns: ["Sevgi::Graphics::Element", "nil"],
        raises: ["Sevgi::ArgumentError"]
      },
      "Sevgi::Function::Math#count" => {
        params: %w[length division],
        returns: ["Integer"],
        raises: ["Sevgi::ArgumentError"]
      },
      "Sevgi::Geometry::Element::Lined#translate" => {
        params: %w[dx dy],
        returns: ["Sevgi::Geometry::Element::Lined"]
      },
      "Sevgi::Geometry::Line#length" => {
        returns: ["Float"]
      },
      "Sevgi::Geometry::Operation.align" => {
        params: %w[element other alignment],
        returns: ["Sevgi::Geometry::Element"],
        raises: [
          "Sevgi::ArgumentError",
          "Sevgi::Geometry::Operation::OperationInapplicableError"
        ]
      },
      "Sevgi::Geometry::Operation.sweep" => {
        params: %w[element initial angle step limit],
        returns: ["Array<Sevgi::Geometry::Line>"],
        raises: [
          "Sevgi::Geometry::Error",
          "Sevgi::Geometry::Operation::OperationError",
          "Sevgi::Geometry::Operation::OperationInapplicableError"
        ],
        yields: true
      },
      "Sevgi::Geometry::Point#x" => {
        returns: ["Float"]
      },
      "Sevgi::Geometry::Rect#top_left" => {
        returns: ["Sevgi::Geometry::Point"]
      },
      "Sevgi::Graphics::Document::Proto#call" => {
        params: %w[objects options],
        returns: ["String"]
      },
      "Sevgi::Graphics::Mixtures::Symbols#Symbols" => {
        params: %w[mod args kwargs],
        returns: ["Sevgi::Graphics::Element"],
        raises: ["Sevgi::ArgumentError"]
      },
      "Sevgi::Standard::Attribute#ignore?" => {
        params: %w[attribute],
        returns: ["Boolean"]
      },
      "Sevgi::Standard::Element#ignore?" => {
        params: %w[element],
        returns: ["Boolean"]
      }
    }.freeze
    DYNAMIC_METHODS = {
      "Sevgi::Derender.evaluate" => -> { [Derender, :evaluate] },
      "Sevgi::Geometry::Element::Lined#translate" => -> { [Geometry::Rect[3, 5], :translate] },
      "Sevgi::Geometry::Line#length" => -> { [Geometry::Line[3, 0], :length] },
      "Sevgi::Geometry::Operation.align" => -> { [Geometry::Operation, :align] },
      "Sevgi::Geometry::Operation.sweep" => -> { [Geometry::Operation, :sweep] },
      "Sevgi::Geometry::Rect#top_left" => -> { [Geometry::Rect[3, 5], :top_left] },
      "Sevgi::Standard::Attribute#ignore?" => -> { [Standard.const_get(:Attribute), :ignore?] },
      "Sevgi::Standard::Element#ignore?" => -> { [Standard.const_get(:Element), :ignore?] }
    }.freeze

    def test_api_private_visibility_matches_runtime
      assert_raises(NameError) { Executor::Source }

      assert_yard_object("Sevgi::Sundries::Grid::Axis")
      assert_yard_object("Sevgi::Sundries::Grid::Axis::Query")
      assert(Sundries::Grid.const_defined?(:Axis, false))
      assert(Sundries::Grid::Axis.const_defined?(:Query, false))
    end

    def test_doc_tasks_are_wired_into_ci
      rakefile = ::File.read(::File.join(ROOT, "Rakefile"))
      workflow = ::File.read(::File.join(ROOT, ".github/workflows/test.yml"))

      assert_includes(rakefile, "task(:doc)")
      assert_includes(rakefile, "task(:check)")
      assert_includes(workflow, "bundle exec rake doc:check")
      assert_includes(workflow, "actions/upload-artifact")
      assert_includes(workflow, ".cache/ruby/doc/api")
    end

    def test_docs_site_links_generated_api
      content = ::File.read(::File.join(ROOT, "showcase/doc/content/compatibility.md"))

      assert_includes(content, "https://www.rubydoc.info/gems/sevgi")
    end

    def test_dynamic_public_surfaces_are_documented
      DYNAMIC_METHODS.each do |path, builder|
        receiver, method = builder.call

        assert_respond_to(receiver, method, path)
        assert_yard_object(path)
      end
    end

    def test_semantic_public_docs_have_contract_tags
      CONTRACTS.each do |path, contract|
        tags = documentation_tags(path)

        Array(contract[:params]).each { assert_includes(tag_names(tags, :param), it, path) }
        Array(contract[:returns]).each { assert_includes(tag_types(tags, :return), it, path) }
        Array(contract[:raises]).each { assert_includes(tag_types(tags, :raise), it, path) }
        assert(yielding?(tags), path) if contract[:yields]
      end
    end

    private

    def assert_yard_object(path)
      assert(yard(path), "Missing YARD object: #{path}")
    end

    def documentation_tags(path)
      object = yard(path) or flunk("Missing YARD object: #{path}")
      overloads = object.tags(:overload)
      sources = overloads.empty? ? [object] : overloads

      sources.flat_map { |source| source.tags.reject { it.tag_name == "overload" } }
    end

    def tag_names(tags, name) = tags.select { it.tag_name == name.to_s }.map(&:name).compact

    def tag_types(tags, name) = tags.select { it.tag_name == name.to_s }.flat_map { it.types || [] }

    def yard(path)
      registry
      YARD::Registry.at(path)
    end

    def registry
      return @registry if @registry

      silence_warnings do
        require "yard"

        YARD::Registry.clear
        YARD::Parser::SourceParser.parse(LIB_FILES)
        @registry = YARD::Registry
      end
    end

    def silence_warnings
      verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = verbose
    end

    def yielding?(tags)
      tags.any? { %w[yield yieldparam yieldreturn].include?(it.tag_name) }
    end
  end
end
