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
    CONSTANT_ALIAS_PREFIXES = %w[Sevgi::F:: Sevgi::SVG::].freeze
    DATA_CLASS_SURFACES = {
      "Sevgi::Executor::Result" => %i[members new],
      "Sevgi::Function::Location" => %i[members new],
      "Sevgi::Function::Shell::Result" => %i[members new],
      "Sevgi::Geometry::LengthAngle" => %i[\[\] members new],
      "Sevgi::Geometry::Point" => %i[\[\] members new],
      "Sevgi::Geometry::Segment" => %i[\[\] members new],
      "Sevgi::Graphics::Margin" => %i[\[\] members new],
      "Sevgi::Graphics::Mixtures::Stop" => %i[members],
      "Sevgi::Graphics::Paper" => %i[\[\] members new]
    }.freeze
    DATA_CLASS_METHODS = DATA_CLASS_SURFACES.values.flatten.uniq.freeze
    DATA_INSTANCE_METHODS = %i[== deconstruct deconstruct_keys eql? hash inspect to_h with].freeze
    EXACT_CONTRACTS = {
      "#SVG" => [[%w[document canvas attributes], ["Sevgi::Graphics::Document::Proto"]]],
      "Sevgi::Toplevel#Paper" => [[%w[width height name unit], %w[Symbol String]]],
      "Sevgi::Toplevel#Paper!" => [[%w[width height name unit], %w[Symbol String]]],
      "Sevgi::Geometry::Segment.horizontal" => [[%w[length], ["Sevgi::Geometry::Segment"]]],
      "Sevgi::Geometry::Segment.vertical" => [[%w[length], ["Sevgi::Geometry::Segment"]]],
      "Sevgi::Graphics::Mixtures::Render#Render" => [[%w[options], ["String"]]],
      "Sevgi::Derender::Node#content" => [[[], ["String"]]],
      "Sevgi::Derender::Node#namespaces" => [[[], ["Hash{String => String}"]]],
      "Sevgi::Derender::Node#find" => [[%w[arg by], ["Sevgi::Derender::Node", "nil"]]],
      "Sevgi::Executor::Result#value" => [[[], %w[Object nil]]],
      "Sevgi::Executor::Result#error" => [[[], ["Sevgi::Executor::Error", "nil"]]],
      "Sevgi::Executor::Result#stack" => [[[], ["Array<String>"]]]
    }.freeze
    PUBLIC_CONSTANTS = %w[
      Sevgi::F
      Sevgi::Geometry::Origin
      Sevgi::Graphics::Attributes
      Sevgi::Graphics::Document::Profile
      Sevgi::Sundries::Export
    ]
      .freeze
    PRIVATE_OBJECTS = %w[
      Sevgi::Executor::Scope
      Sevgi::Executor::Source
      Sevgi::Executor::State
      Sevgi::Geometry::Equation::Quadratic
      Sevgi::Sundries::Export::Renderer
    ]
      .freeze
    CONSTRUCTORS = {
      "Sevgi::Executor" => false,
      "Sevgi::Executor::Error" => true,
      "Sevgi::Executor::Result" => true,
      "Sevgi::Geometry::Element" => false,
      "Sevgi::Geometry::Element::Lined" => false,
      "Sevgi::Graphics::Content" => false,
      "Sevgi::Graphics::Content::CData" => false,
      "Sevgi::Graphics::Content::CSS" => false,
      "Sevgi::Graphics::Content::Encoded" => false,
      "Sevgi::Graphics::Content::Verbatim" => false,
      "Sevgi::Graphics::Element" => false,
      "Sevgi::Sundries::Grid::Axis" => false,
      "Sevgi::Sundries::Grid::Axis::Query" => false,
      "Sevgi::Sundries::Grid::X" => false,
      "Sevgi::Sundries::Grid::Y" => false
    }.freeze
    WORKFLOW_EXAMPLES = %w[
      Sevgi::Derender
      Sevgi::Executor
      Sevgi::Geometry
      Sevgi::Graphics
      Sevgi::Standard
      Sevgi::Sundries::Export
    ]
      .freeze

    def test_api_private_visibility_matches_runtime
      assert_raises(NameError) { Executor::Source }

      assert_yard_object("Sevgi::Sundries::Grid::Axis")
      assert_yard_object("Sevgi::Sundries::Grid::Axis::Query")
      assert(Sundries::Grid.const_defined?(:Axis, false))
      assert(Sundries::Grid::Axis.const_defined?(:Query, false))
    end

    def test_api_private_methods_are_runtime_private
      exposed = registry.all(:method).filter_map do |object|
        next unless object.tag(:api)&.text == "private"
        next if effective_private?(object.namespace) || !feature_loaded?(object.file)

        object.path if runtime_public?(object)
      end

      assert_empty(exposed, "Private API methods exposed at runtime:\n#{exposed.join("\n")}")
    end

    def test_constructor_support_is_explicit
      CONSTRUCTORS.each do |path, supported|
        owner = runtime_constant(path)
        constructor = yard("#{path}#initialize")
        documented = constructor && !effective_private?(constructor)

        assert_equal(supported, owner.respond_to?(:new), "#{path}.new support")
        assert_equal(supported, !!documented, "#{path}.new documentation")
      end
    end

    def test_data_class_surfaces_are_explicit
      classes = runtime_modules.select { data_class?(it) }

      assert_equal(DATA_CLASS_SURFACES.keys.sort, classes.map(&:name).sort)
      classes.each do |owner|
        expected = DATA_CLASS_SURFACES.fetch(owner.name)
        %i[\[\] members new].each do |name|
          assert_equal(expected.include?(name), owner.respond_to?(name), "#{owner.name}.#{name} support")
        end
      end
    end

    def test_documented_method_visibility_matches_runtime
      errors = registry.all(:method).filter_map { visibility_error(it) }

      assert_empty(errors, errors.join("\n"))
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
      assert_includes(rakefile, "SevgiBuild::Docs.verify!")
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

    def test_high_value_contracts_are_exact
      EXACT_CONTRACTS.each do |path, expected|
        object = yard(path)
        actual = contract_sources(object).map do |source|
          returns = source.tags(:return).flat_map { it.types || [] }.uniq
          [expected_params(source), returns]
        end

        assert_equal(expected, actual, path)
      end
    end

    def test_public_docs_exclude_tool_directives
      errors = public_objects.filter_map do |object|
        next unless object.docstring.to_s.match?(/\b(?:rubocop|standard|reek):(?:disable|enable)\b/i)

        object.path
      end

      assert_empty(errors, "Tool directives in public docs:\n#{errors.join("\n")}")
    end

    def test_core_workflows_have_examples
      missing = WORKFLOW_EXAMPLES.reject { yard(it).tags(:example).any? }

      assert_empty(missing, "Core workflows without examples:\n#{missing.join("\n")}")
    end

    def test_constant_visibility_matches_documentation
      errors = registry
        .all
        .select { %i[class module].include?(it.type) && feature_loaded?(it.file) }
        .filter_map { constant_visibility_error(it) }

      assert_empty(errors, errors.join("\n"))

      missing = runtime_constant_paths.reject { documented_constant?(it) }

      assert_empty(missing, "Runtime constants missing from YARD:\n#{missing.join("\n")}")
    end

    def test_public_inventory_handles_method_shapes
      paths = intended_methods.map(&:path)
      Graphics::Element.root { marker }
      runtime = runtime_methods

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

      %w[
        Sevgi::Function.changed?
        Sevgi::Geometry::Triangle.from_points
        Sevgi::Geometry::Triangle#A
        Sevgi::Graphics::Document::Minimal#Render
        Sevgi::Graphics::Element#marker
        Sevgi::Graphics::Paper.members
      ]
        .each { assert_includes(runtime, it) }
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

    def constant_visibility_error(object)
      expected = effective_private?(object) ? :private : :public
      actual = public_constant_path?(object.path) ? :public : :private
      "#{object.path}: documented #{expected}, runtime #{actual}" unless expected == actual
    end

    def documented_runtime_method?(path)
      entry = runtime_entries.fetch(path)
      public_yard_method?(yard(path)) || generated_runtime_method?(path, entry)
    end

    def data_class?(owner) = owner.is_a?(::Class) && owner < ::Data

    def data_protocol_method?(entry)
      return false unless data_class?(entry[:target])

      methods = if entry[:scope] == :class
        DATA_CLASS_SURFACES.fetch(entry[:target].name)
      else
        DATA_INSTANCE_METHODS
      end

      methods.include?(entry[:name])
    end

    def defining_yard_method?(entry)
      defining_method_paths(entry).any? { public_yard_method?(yard(it)) }
    end

    def defining_method_paths(entry)
      owner = entry[:method].owner
      paths = owner_method_paths(owner, entry[:name])
      separator = entry[:scope] == :class ? "." : "#"
      paths.concat(
        entry[:target].ancestors.filter_map do |ancestor|
          "#{ancestor.name}#{separator}#{entry[:name]}" if ancestor.name
        end
      )
    end

    def generated_runtime_method?(path, entry)
      paper_profile?(path) ||
        data_protocol_method?(entry) ||
        ruby_protocol_method?(entry) ||
        defining_yard_method?(entry) ||
        dynamic_element_method?(entry)
    end

    def owner_method_paths(owner, name)
      return ["#{owner.name}##{name}", "#{owner.name}.#{name}"] if owner.name

      target = runtime_modules.find { it.singleton_class.equal?(owner) }
      target ? ["#{target.name}.#{name}"] : []
    end

    def public_yard_method?(object)
      object && object.visibility == :public && !effective_private?(object)
    end

    def ruby_protocol_method?(entry)
      entry[:scope] == :instance && entry[:name] == :message && entry[:target] <= ::Exception
    end

    def dynamic_element_method?(entry)
      return false unless entry[:scope] == :instance
      return false unless entry[:target].is_a?(::Class) && entry[:target] <= Graphics::Element

      Graphics::Element.valid?(Graphics::Element.send(:id, entry[:name]))
    end

    def documented_constant?(path)
      yard(path) || CONSTANT_ALIAS_PREFIXES.any? { path.start_with?(it) }
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

    def public_objects
      registry
        .all
        .reject { effective_private?(it) }
        .reject { it.type == :method && it.visibility != :public }
    end

    def public_constant_path?(path)
      path.split("::").reject(&:empty?).inject(::Object) do |owner, name|
        return false unless owner.is_a?(::Module) && owner.constants(false).include?(name.to_sym)

        owner.const_get(name, false)
      end

      true
    rescue NameError
      false
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

    def runtime_public?(object)
      owner = runtime_constant(object.namespace.path)
      object.scope == :class ? owner.respond_to?(object.name) : owner.public_method_defined?(object.name)
    rescue NameError
      false
    end

    def runtime_visibility(object)
      owner = runtime_constant(object.namespace.path)
      owner = owner.singleton_class if object.scope == :class

      %i[public protected private].find { owner.public_send("#{it}_method_defined?", object.name) }
    rescue NameError
      nil
    end

    def visibility_error(object)
      return unless visibility_checked?(object)

      actual = runtime_visibility(object)
      return unless actual && actual != object.visibility

      "#{object.path}: documented #{object.visibility}, runtime #{actual}"
    end

    def visibility_checked?(object)
      object.name != :initialize &&
        object.namespace != YARD::Registry.root &&
        !effective_private?(object) &&
        feature_loaded?(object.file)
    end

    def runtime_constant_paths
      queue = [[::Sevgi, "Sevgi"]]
      paths = []

      until queue.empty?
        owner, prefix = queue.shift
        owner.constants(false).sort.each do |name|
          location = owner.const_source_location(name, false)&.first
          next unless location && LIB_FILES.include?(::File.expand_path(location))

          path = "#{prefix}::#{name}"
          value = owner.const_get(name, false)

          paths << path
          queue << [value, path] if value.is_a?(::Module)
        end
      end

      paths.uniq.sort
    end

    def runtime_entries
      @runtime_entries ||= runtime_modules.each_with_object({}) do |owner, entries|
        owner.public_instance_methods.each do |name|
          method = owner.instance_method(name)
          next unless project_runtime_method?(owner, method, name, :instance)

          entries["#{owner.name}##{name}"] = {target: owner, method:, name:, scope: :instance}
        end

        owner.public_methods.each do |name|
          method = owner.method(name)
          next unless project_runtime_method?(owner, method, name, :class)

          entries["#{owner.name}.#{name}"] = {target: owner, method:, name:, scope: :class}
        end
      end
    end

    def runtime_methods = runtime_entries.keys.sort

    def runtime_modules
      @runtime_modules ||= runtime_constant_paths
        .filter_map { runtime_constant_or_nil(it) }
        .select { it.is_a?(::Module) && it.name&.start_with?("Sevgi") }
        .prepend(::Sevgi)
        .uniq
    end

    def project_runtime_method?(target, method, name, scope)
      file = method.source_location&.first
      return LIB_FILES.include?(::File.expand_path(file)) if file
      return false unless data_class?(target)

      methods = scope == :class ? DATA_CLASS_METHODS : DATA_INSTANCE_METHODS
      methods.include?(name)
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
