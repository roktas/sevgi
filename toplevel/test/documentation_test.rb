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
    CONTRACT_TAGS = %w[param raise return yield yieldparam yieldreturn].freeze
    GENERIC_RETURNS = %w[Array Hash Object].freeze
    PUBLIC_CONSTANTS = %w[
      Sevgi::F
      Sevgi::Geometry::Origin
      Sevgi::Graphics::Document::Profile
      Sevgi::Sundries::Export
    ]
      .freeze
    PRIVATE_OBJECTS = %w[
      Sevgi::Executor::Scope
      Sevgi::Executor::Source
      Sevgi::Geometry::Equation::Quadratic
      Sevgi::Sundries::Export::Renderer
    ]
      .freeze

    def test_api_private_visibility_matches_runtime
      assert_raises(NameError) { Executor::Source }

      assert_yard_object("Sevgi::Sundries::Grid::Axis")
      assert_yard_object("Sevgi::Sundries::Grid::Axis::Query")
      assert(Sundries::Grid.const_defined?(:Axis, false))
      assert(Sundries::Grid::Axis.const_defined?(:Query, false))
    end

    def test_public_manifest_and_private_pages_are_explicit
      PUBLIC_CONSTANTS.each { assert_yard_object(it) }
      PRIVATE_OBJECTS.each { assert_equal("private", yard(it).tag(:api)&.text, it) }
    end

    def test_doc_tasks_are_wired_into_ci
      rakefile = ::File.read(::File.join(ROOT, "Rakefile"))
      workflow = ::File.read(::File.join(ROOT, ".github/workflows/test.yml"))

      assert_includes(rakefile, "task(:doc)")
      assert_includes(rakefile, "task(:check)")
      assert_includes(rakefile, "SevgiBuild::Docs.complete!")
      assert_includes(::File.read(::File.join(ROOT, ".yardopts")), "--hide-api private")
      assert_includes(workflow, "bundle exec rake doc:check")
      assert_includes(workflow, "actions/upload-artifact")
      assert_includes(workflow, ".cache/ruby/doc/api")
    end

    def test_docs_site_links_generated_api
      content = ::File.read(::File.join(ROOT, "showcase/doc/content/compatibility.md"))

      assert_includes(content, "https://www.rubydoc.info/gems/sevgi")
    end

    def test_public_method_inventory_matches_runtime
      missing = intended_methods.reject { runtime_method?(it) }.map(&:path)
      unexpected = runtime_methods.reject { documented_runtime_method?(it) }

      assert_empty(missing, "Documented methods missing at runtime:\n#{missing.join("\n")}")
      assert_empty(unexpected, "Runtime methods missing from YARD:\n#{unexpected.join("\n")}")
    end

    def test_public_methods_have_complete_contracts
      errors = intended_methods.flat_map { contract_errors(it) }

      assert_empty(errors, errors.join("\n"))
    end

    def test_public_inventory_handles_method_shapes
      paths = intended_methods.map(&:path)

      assert_operator(paths.size, :>, 500)
      %w[
        Sevgi::Function::Locate.call
        Sevgi::Function::Locate#call
        Sevgi::Function::Locate#exclude
        Sevgi::Function::File#existing_map!
        Sevgi::Geometry::Line#length
        Sevgi::Graphics::Margin#to_a
      ]
        .each { assert_includes(paths, it) }
    end

    private

    def assert_yard_object(path)
      assert(yard(path), "Missing YARD object: #{path}")
    end

    def alias_target(object)
      name = object.namespace.aliases.fetch(object)
      separator = object.scope == :class ? "." : "#"
      yard("#{object.namespace.path}#{separator}#{name}")
    end

    def contract_errors(object)
      contract_sources(object).each_with_index.flat_map do |source, index|
        label = object.tags(:overload).empty? ? object.path : "#{object.path} overload #{index + 1}"
        source_errors(object, source, label)
      end
    end

    def contract_sources(object)
      overloads = object.tags(:overload)
      return overloads unless overloads.empty?
      return [object] unless object.is_alias?

      target = alias_target(object)
      target ? contract_sources(target) : [object]
    end

    def contract_tags(source) = source.tags.select { CONTRACT_TAGS.include?(it.tag_name) }

    def documented_runtime_method?(path)
      return true if yard(path)
      return true if paper_profile?(path)

      dynamic_element_method?(path)
    end

    def dynamic_element_method?(path)
      prefix = "Sevgi::Graphics::Element#"
      return false unless path.start_with?(prefix)

      name = path.delete_prefix(prefix).to_sym
      Graphics::Element.valid?(Graphics::Element.send(:id, name))
    end

    def effective_private?(object)
      current = object
      while current && current != YARD::Registry.root
        return true if current.tag(:api)&.text == "private"

        current = current.namespace
      end

      false
    end

    def expected_params(source)
      source
        .parameters
        .reject { |name, _default| name.to_s.start_with?("&") }
        .map { |name, _default| name.to_s.sub(/\A\*+/, "").delete_suffix(":") }
        .reject { it.empty? || it == "..." }
    end

    def feature_loaded?(file)
      path = ::File.expand_path(file, ROOT)
      $LOADED_FEATURES.any? { ::File.expand_path(it) == path }
    end

    def intended_methods
      registry
        .all(:method)
        .select { it.visibility == :public && !effective_private?(it) }
        .sort_by(&:path)
    end

    def paper_profile?(path)
      prefix = "Sevgi::Graphics::Paper."
      return false unless path.start_with?(prefix)

      name = path.delete_prefix(prefix).to_sym
      Graphics::Paper.exist?(name) && Graphics::Paper.public_send(name).is_a?(Graphics::Paper)
    end

    def precise_return?(tag)
      types = tag.types || []
      return false if types.empty?
      return true unless types.intersect?(GENERIC_RETURNS)

      !tag.text.to_s.strip.empty?
    end

    def runtime_constant(path)
      path.split("::").reject(&:empty?).inject(::Object) { |owner, name| owner.const_get(name, false) }
    end

    def runtime_method?(object)
      return true unless feature_loaded?(object.file)
      return top_level_method?(object) if object.namespace == YARD::Registry.root

      owner = runtime_constant(object.namespace.path)
      return owner.respond_to?(object.name) if object.scope == :class
      return owner.private_method_defined?(:initialize) if object.name == :initialize

      owner.public_method_defined?(object.name)
    rescue NameError
      false
    end

    def runtime_methods
      registry
        .all
        .select { %i[class module].include?(it.type) && !effective_private?(it) }
        .filter_map { runtime_constant_or_nil(it.path) }
        .uniq
        .flat_map { runtime_paths(it) }
        .uniq
        .sort
    end

    def runtime_paths(owner)
      instance = owner.public_instance_methods(false).filter_map do |name|
        runtime_path(owner, name, owner.instance_method(name), "#")
      end

      singleton = owner.singleton_methods(false).filter_map do |name|
        runtime_path(owner, name, owner.method(name), ".")
      end

      instance + singleton
    end

    def runtime_path(owner, name, method, separator)
      file = method.source_location&.first
      return unless file && ::File.file?(file) && ::File.expand_path(file).start_with?("#{ROOT}/")

      "#{owner.name}#{separator}#{name}"
    end

    def runtime_constant_or_nil(path)
      runtime_constant(path)
    rescue NameError
      nil
    end

    def source_errors(object, source, label)
      tags = contract_tags(source)
      errors = parameter_errors(source, tags, label)
      returns = tags.select { it.tag_name == "return" }
      errors << "#{label}: missing precise @return" if returns.empty? || returns.any? { !precise_return?(it) }
      errors.concat(raise_errors(tags, label))
      errors.concat(yield_errors(object, source, tags, label))
      errors
    end

    def parameter_errors(source, tags, label)
      expected = expected_params(source).sort
      actual = tags.select { it.tag_name == "param" }.map(&:name).compact.sort
      errors = []
      errors << "#{label}: @param #{actual.inspect}, expected #{expected.inspect}" unless actual == expected
      tags.select { it.tag_name == "param" }.each do |tag|
        errors << "#{label}: incomplete @param #{tag.name}" if (tag.types || []).empty? || tag.text.to_s.strip.empty?
      end

      errors
    end

    def raise_errors(tags, label)
      raises = tags.select { it.tag_name == "raise" }
      raises.filter_map do |tag|
        next if tag.types&.one? && !tag.text.to_s.strip.empty?

        "#{label}: each @raise needs one exception type and a condition"
      end
    end

    def top_level_method?(object)
      ::Object.public_method_defined?(object.name) || ::Object.private_method_defined?(object.name)
    end

    def yield_errors(object, source, tags, label)
      return [] unless yields?(object, source)

      names = tags.map(&:tag_name)
      errors = []
      errors << "#{label}: missing @yield" unless names.include?("yield")
      yieldreturns = tags.select { it.tag_name == "yieldreturn" }
      errors << "#{label}: missing precise @yieldreturn" unless precise_yieldreturn?(yieldreturns)

      errors
    end

    def yields?(object, source)
      sources = [source, object]
      sources.any? { it.parameters.any? { |name, _default| name.to_s.start_with?("&") } } ||
        (object.is_explicit? && object.source&.match?(/\byield(?:\s|\()/))
    end

    def precise_yieldreturn?(tags) = !tags.empty? && tags.all? { (it.types || []).any? }

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

  end
end
