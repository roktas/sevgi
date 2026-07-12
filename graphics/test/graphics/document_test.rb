# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    module Document
      class Test < Base
        document :test, attributes: {"data-var": "xxx"}
      end
    end

    class DocumentProfileTest < Minitest::Test
      DOC = :test

      class MutableValue
        attr_reader :calls, :text

        def initialize(text)
          @calls = 0
          @text = text
        end

        def to_s
          @calls += 1
          text
        end
      end

      class PausedValue
        def initialize(entered, release)
          @entered = entered
          @release = release
        end

        def to_s
          @entered << true
          @release.pop
          "red"
        end
      end

      class Gate < Hash
        def initialize(source, target, entered, release)
          super()
          update(source)
          @blocked = false
          @entered = entered
          @release = release
          @target = target
        end

        def [](name)
          value = super
          if name == @target && !@blocked
            @blocked = true
            @entered << true
            @release.pop
          end

          value
        end
      end

      private_constant :Gate, :MutableValue, :PausedValue

      def test_default_profile_renders_preamble_and_namespace
        expected = <<~SVG
          <?xml version="1.0" standalone="no"?>
          <svg xmlns="http://www.w3.org/2000/svg"/>
        SVG
          .chomp

        assert_equal(expected, SVG(:default).Render())
      end

      def test_html_profile_suppresses_preambles
        expected = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg"/>
        SVG
          .chomp

        assert_equal(expected, SVG(:html).Render())
      end

      def test_anonymous_document_doesnt_replace_default
        before = SVG(:default).Render()
        doc = Graphics.document(attributes: {"data-var": "anonymous"})

        [
          before,
          SVG(:default).Render(),
          "<svg data-var=\"anonymous\"/>",
          SVG(doc).Render()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_named_document_lookup_returns_builtin_profiles
        {
          base: Document::Base,
          minimal: Document::Minimal,
          default: Document::Default,
          html: Document::HTML,
          inkscape: Document::Inkscape
        }.each do |name, klass|
          assert_same(klass, Graphics.document(name))
        end
      end

      def test_profile_and_document_lookup_are_distinct
        profile = Document.profile(:minimal)
        keys = Document.keys

        assert_instance_of(Document::Profile, profile)
        assert_same(Document::Minimal, Document.fetch(:minimal))
        assert_same(profile, Document::Minimal.profile)
        assert_includes(keys, :minimal)
        assert_predicate(keys, :frozen?)
        assert_raises(FrozenError) { keys.clear }
      end

      def test_document_classes_inherit_nearest_profile
        inherited = Class.new(Document::Minimal)
        nested = Class.new(inherited)
        anonymous = Graphics.document(attributes: {viewBox: "0 0 2 2"})
        anonymous_child = Class.new(anonymous)

        [inherited, nested].each do |klass|
          assert_same(Document::Minimal.profile, klass.profile)
          assert_equal("<svg/>", SVG(klass).Render())
        end

        assert_same(anonymous.profile, anonymous_child.profile)
        assert_equal("<svg viewBox=\"0 0 2 2\"/>", SVG(anonymous_child).Render())
      end

      def test_document_class_inputs_require_a_profile
        orphan = Class.new(Document::Proto)

        assert_instance_of(Document::Proto, SVG(Document::Proto))
        assert_raises(Sevgi::ArgumentError) { SVG(orphan) }
        assert_raises(Sevgi::ArgumentError) { orphan.root.Render() }
        assert_raises(Sevgi::ArgumentError) { SVG(String) }
      end

      def test_document_construction_surface_is_closed
        [Document::Proto, Document::Base, Document::Minimal].each do |klass|
          assert_raises(NoMethodError) { klass.new }
          refute_respond_to(klass, :document)
          refute_respond_to(klass, :mixture)
        end

        assert_raises(NameError) { Document::DEFAULTS }

        custom = Class.new(Document::Minimal) do
          document(
            :private_document_dsl,
            attributes: {viewBox: "0 0 3 3"}
          )
        end

        assert_equal("<svg viewBox=\"0 0 3 3\"/>", SVG(custom).Render())
      end

      def test_document_exist_reports_registered_profiles
        invalid = Object.new.tap { it.define_singleton_method(:to_sym) { raise "broken" } }
        before = Document.keys

        assert(Document.exist?(:minimal))
        assert(Document.exist?("minimal"))
        refute(Document.exist?(:missing))
        refute(Document.exist?(Object.new))
        refute(Document.exist?(invalid))
        assert_equal(before, Document.keys)
      end

      def test_profile_registry_is_not_public
        before = Document.keys

        refute_respond_to(Document::Profile, :register)
        assert_raises(NoMethodError) { Document::Profile.register(:broken, String) }
        assert_equal(before, Document.keys)
        assert_raises(ArgumentError) { SVG(:broken) }
      end

      def test_profile_has_complete_value_semantics
        profile = Document::Profile.new(:value_profile, attributes: {viewBox: [0, 0, 1, 1]}, preambles: ["header"])
        equivalent = Document::Profile.new(:value_profile, attributes: {viewBox: [0, 0, 1, 1]}, preambles: ["header"])

        assert_equal(profile, equivalent)
        assert(profile.eql?(equivalent))
        assert_equal(profile.hash, equivalent.hash)
        assert_equal(:found, {profile => :found}[equivalent])
        assert_predicate(profile, :frozen?)
      end

      def test_profile_registry_rejects_invalid_classes
        registry = Document.const_get(:Registry, false)
        before = Document.keys
        invalid = [
          [String, nil],
          [Class.new(Document::Proto), nil],
          [Document::Minimal, Document::Minimal.profile],
          [Object.new, nil]
        ]

        invalid.each do |klass, profile|
          assert_raises(ArgumentError) { registry.register(:broken, klass, profile:) }
          assert_equal(before, Document.keys)
        end
      end

      def test_profile_registry_rejects_invalid_names
        registry = Document.const_get(:Registry, false)
        before = Document.keys
        raising = Object.new.tap { it.define_singleton_method(:to_sym) { raise "conversion failed" } }
        wrong = Object.new.tap { it.define_singleton_method(:to_sym) { "broken" } }

        [Object.new, raising, wrong].each do |name|
          assert_nil(Document::Profile.normalize(name))
          assert_raises(ArgumentError) { registry.register(name, Document::Minimal) }
          assert_equal(before, Document.keys)
        end
      end

      def test_profile_registry_serializes_conflicting_writes
        registry = Document.const_get(:Registry, false)
        original = registry.instance_variable_get(:@available)
        name = :registered_thread_atomic
        values = racing_registrations(registry, original, name)
        classes, errors = values.partition { it.is_a?(::Class) }

        assert_equal(1, classes.size)
        assert_equal([Sevgi::ArgumentError], errors.map(&:class))
        assert_same(classes.fetch(0), registry[name])
      ensure
        registry.instance_variable_set(:@available, original)
      end

      def test_named_document_registers_profile_and_class
        doc = Graphics.document(:registered, attributes: {"data-var": "registered"})

        [
          "<svg data-var=\"registered\"/>",
          SVG(:registered).Render(),
          "<svg data-var=\"registered\"/>",
          SVG(doc).Render()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_named_document_preserves_existing_profile
        doc = Graphics.document(:registered_safe, attributes: {"data-var": "safe"})
        again = Graphics.document(:registered_safe, attributes: {"data-var": "safe"})

        assert_same(doc, again)
      end

      def test_named_document_race_returns_canonical_class
        name = :registered_concurrent_same
        classes = concurrent_documents(name)

        assert(classes.all?(::Class))
        assert_same(classes.first, classes.last)
        assert_same(classes.first, Graphics.document(name))
      end

      def test_named_document_allows_omitted_matching_fields
        doc = Graphics.document(:registered_partial, attributes: {"data-var": "safe"}, preambles: ["one"])

        [
          doc,
          Graphics.document(:registered_partial),
          doc,
          Graphics.document(:registered_partial, attributes: {"data-var": "safe"}),
          doc,
          Graphics.document(:registered_partial, preambles: ["one"])
        ].each_slice(2) { |expected, actual| assert_same(expected, actual) }
      end

      def test_named_document_normalizes_profile_names
        Graphics.document("registered_string", attributes: {"data-var": "string"})

        [
          "<svg data-var=\"string\"/>",
          SVG(:registered_string).Render(),
          "<svg data-var=\"string\"/>",
          SVG("registered_string").Render()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_named_document_rejects_conflicting_profile
        Graphics.document(:registered_conflict, attributes: {"data-var": "first"})

        error = assert_raises(ArgumentError) do
          Graphics.document(:registered_conflict, attributes: {"data-var": "second"})
        end

        assert_match(/\bregistered_conflict\b/, error.message)
      end

      def test_named_document_rejects_preamble_conflict
        Graphics.document(:registered_pres, preambles: ["one"])

        error = assert_raises(ArgumentError) do
          Graphics.document(:registered_pres, preambles: ["two"])
        end

        assert_match(/\bregistered_pres\b/, error.message)
      end

      def test_named_document_conflict_keeps_registration_atomic
        doc = Graphics.document(:registered_atomic, attributes: {style: {fill: "red"}})
        attributes = {style: {fill: "blue"}}

        assert_raises(ArgumentError) do
          Graphics.document(:registered_atomic, attributes:)
        end

        attributes[:style][:fill] = "green"

        assert_same(doc, Graphics.document(:registered_atomic))
        assert_equal({fill: "red"}, doc.attributes[:style])
      end

      def test_define_rejects_non_boolean_overwrite_atomically
        name = :registered_boolean_overwrite
        current = Document.define(name, attributes: {fill: "red"})
        before = Document.keys

        [nil, 0, "false", :enabled].each do |overwrite|
          value = MutableValue.new("blue")
          error = assert_raises(Sevgi::ArgumentError) do
            Document.define(name, attributes: {fill: value}, overwrite:)
          end

          assert_match(/overwrite must be true or false/i, error.message)
          assert_equal(0, value.calls)
          assert_equal(before, Document.keys)
          assert_same(current, Document.fetch(name))
          assert_equal({fill: "red"}, current.profile.attributes)
        end

        assert_raises(Sevgi::ArgumentError) do
          Document.define(attributes: {}, overwrite: "false")
        end
      end

      def test_document_profile_copies_input_attributes
        attributes = {style: {fill: "red"}, viewBox: [0, 0, 1, 1]}
        doc = Graphics.document(:registered_attribute_copy, attributes:)

        attributes[:style][:fill] = "blue"
        attributes[:viewBox] << 2

        [
          {fill: "red"},
          doc.attributes[:style],
          [0, 0, 1, 1],
          doc.attributes[:viewBox]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_document_profile_copies_input_preambles
        preambles = ["one"]
        doc = Graphics.document(:registered_preamble_copy, preambles:)

        preambles << "two"

        assert_equal(["one"], doc.preambles)
      end

      def test_document_profile_returns_attribute_snapshots
        doc = Graphics.document(:registered_attribute_snapshot, attributes: {style: {fill: "red"}, viewBox: [0, 0]})
        attributes = doc.attributes

        attributes[:style][:fill] = "blue"
        attributes[:viewBox] << 1

        [
          {fill: "red"},
          doc.attributes[:style],
          [0, 0],
          doc.attributes[:viewBox]
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_document_profile_returns_preamble_snapshots
        doc = Graphics.document(:registered_preamble_snapshot, preambles: ["one"])

        doc.preambles << "two"

        assert_equal(["one"], doc.preambles)
      end

      def test_document_rejects_cyclic_profile_metadata
        current = Graphics.document(:registered_cycle_safe, attributes: {fill: "red"})
        hash = {}
        hash[:self] = hash
        array = []
        array << array
        before = Document.keys
        operations = [
          -> { Document::Profile.new(nil, attributes: hash) },
          -> { Graphics.document(attributes: hash) },
          -> { Graphics.document(:registered_cycle_hash, attributes: hash) },
          -> { Graphics.document(:registered_cycle_array, attributes: {viewBox: array}) },
          -> { Graphics.document!(:registered_cycle_safe, attributes: hash) },
          -> { Class.new(Document::Base) { document(:registered_cycle_class, attributes: hash) } }
        ]

        operations.each do |operation|
          error = assert_raises(Sevgi::ArgumentError, &operation)
          assert_match(/cyclic document profile metadata/i, error.message)
          assert_equal(before, Document.keys)
        end

        assert_same(current, Graphics.document(:registered_cycle_safe))
        assert_equal("<svg fill=\"red\"/>", SVG(:registered_cycle_safe).Render())
      end

      def test_document_validates_profile_metadata_shape
        before = Document.keys
        cyclic = []
        cyclic << cyclic
        invalid = [
          {attributes: []},
          {attributes: "fill"},
          {attributes: {Object.new => "red"}},
          {attributes: {"fill" => "red", :fill => "blue"}},
          {preambles: "header"},
          {preambles: ["header", 1]},
          {preambles: cyclic}
        ]

        invalid.each do |metadata|
          assert_raises(Sevgi::ArgumentError) do
            Graphics.document(:registered_invalid_metadata, **metadata)
          end

          assert_equal(before, Document.keys)
        end
      end

      def test_document_rejects_invalid_preamble_without_coercion
        preamble = MutableValue.new("header")
        before = Document.keys

        assert_raises(Sevgi::ArgumentError) do
          Graphics.document(:registered_invalid_preamble, preambles: [preamble])
        end

        assert_equal(0, preamble.calls)
        assert_equal(before, Document.keys)
      end

      def test_document_owns_mutable_profile_values
        value = MutableValue.new(+"red")
        shared = [1, 2]
        doc = Graphics.document(
          :registered_mutable_value,
          attributes: {
            style: {fill: value},
            first: shared,
            second: shared,
            count: 2,
            flag: false,
            omitted: nil,
            token: :round
          }
        )

        value.text.replace("blue")
        shared << 3
        attributes = doc.attributes
        attributes[:style][:fill].replace("green")
        attributes[:first] << 4

        assert_equal(1, value.calls)
        assert_equal({fill: "red"}, doc.attributes[:style])
        assert_equal([1, 2], doc.attributes[:first])
        assert_equal([1, 2], doc.attributes[:second])
        assert_equal([2, false, nil, :round], doc.attributes.values_at(:count, :flag, :omitted, :token))
        expected = "<svg style=\"fill:red\" first=\"1 2\" second=\"1 2\" count=\"2\" flag=\"false\" token=\"round\"/>"
        assert_equal(expected, SVG(doc).Render())
      end

      def test_document_rejects_value_stringification_errors
        raising = Object.new.tap { it.define_singleton_method(:to_s) { raise "broken" } }
        wrong = Object.new.tap { it.define_singleton_method(:to_s) { Object.new } }
        before = Document.keys

        [raising, wrong].each do |value|
          error = assert_raises(Sevgi::ArgumentError) do
            Graphics.document(:registered_bad_value, attributes: {fill: value})
          end

          assert_match(/profile metadata (?:cannot be|stringification)/i, error.message)
          assert_equal(before, Document.keys)
        end

        left = MutableValue.new("same")
        right = MutableValue.new("same")
        error = assert_raises(Sevgi::ArgumentError) do
          Graphics.document(:registered_bad_value, attributes: {style: {left => 1, right => 2}})
        end

        assert_match(/metadata keys collide after stringification/i, error.message)
        assert_equal(before, Document.keys)
      end

      def test_document_rejects_invalid_xml_metadata
        current = Graphics.document(:registered_xml_safe, attributes: {fill: "red"})
        before = Document.keys
        operations = [
          -> { Graphics.document(:registered_xml_value, attributes: {fill: "illegal\0value"}) },
          -> { Graphics.document(:registered_xml_name, attributes: {"bad name" => "value"}) },
          -> { Graphics.document(preambles: ["illegal\0preamble"]) },
          -> { Graphics.document(preambles: ["\xFF".b]) },
          -> { Graphics.document!(:registered_xml_safe, preambles: ["illegal\0preamble"]) }
        ]

        operations.each do |operation|
          error = assert_raises(Sevgi::ArgumentError, &operation)

          assert_match(/document profile metadata|document profile attribute name/i, error.message)
          assert_equal(before, Document.keys)
        end

        assert_same(current, Graphics.document(:registered_xml_safe))
        assert_equal("<svg fill=\"red\"/>", SVG(:registered_xml_safe).Render())
      end

      def test_document_bang_overwrites_profile
        first = Graphics.document!(:registered_force, attributes: {"data-var": "first"})
        second = Graphics.document!(:registered_force, attributes: {"data-var": "second"})

        [
          false,
          first.equal?(second),
          "<svg data-var=\"second\"/>",
          SVG(:registered_force).Render()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_class_document_preserves_existing_profile
        klass = Class.new(Document::Base) { document(:test, attributes: {"data-var": "xxx"}) }

        [
          Document::Test,
          SVG(:test).class,
          "<svg data-var=\"xxx\"/>",
          SVG(klass).Render()
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_subclass_root_attributes_doesnt_leak
        expected = <<~SVG
          <svg data-var="xxx">
            <line data-var="main var"/>
            <line data-var="duplicated var"/>
          </svg>
        SVG
          .chomp

        actual = SVG(DOC) do
          line("data-var": "main var").Duplicate()[:"data-var"] = "duplicated var"
        end
          .Render()

        assert_equal(expected, actual)
      end

      def test_subclass_renders_default_canvas
        expected = <<~SVG
          <svg data-var="xxx" width="210.0mm" height="297.0mm" viewBox="0 0 210 297"/>
        SVG
          .chomp

        actual = SVG(DOC, Canvas.from_paper(:a4)).Render()

        assert_equal(expected, actual)
      end

      def test_subclass_renders_custom_canvas
        expected = <<~SVG
          <svg data-var="xxx" width="210.0mm" height="297.0mm" viewBox="-5 -3 210 297"/>
        SVG
          .chomp

        actual = SVG(DOC, Canvas.from_paper(:a4, margins: [3, 5])).Render()

        assert_equal(expected, actual)
      end

      def test_unknown_profile_raises_argument_error
        error = assert_raises(ArgumentError) { SVG(:missing) }

        assert_match(/\bmissing\b/, error.message)
      end

      def test_document_lookup_does_not_define_unknown_profile
        assert_raises(ArgumentError) { Graphics.document(:lookup_missing) }
        assert_raises(ArgumentError) { SVG(:lookup_missing) }
      end

      def test_document_explicit_empty_definition_is_registered
        doc = Graphics.document(:explicit_empty, attributes: {})

        assert_same(doc, Graphics.document(:explicit_empty))
        assert_equal("<svg/>", SVG(:explicit_empty).Render())
      end

      def test_document_call_renders_without_positionals
        document = SVG(:minimal) { rect(width: 3) }

        assert_equal("<svg>\n  <rect width=\"3\"/>\n</svg>", document.call)
        assert_raises(::ArgumentError) { document.call(:unused) }
      end

      def test_document_call_separates_option_channels
        checks = nil
        klass = Graphics.document
        klass.class_eval do
          define_method(:PreRender) { |**options| checks = options }
        end

        document = SVG(klass) { rect }

        assert_match(%r{<rect/>}, document.call(lint: false, style: :inline))
        assert_equal({lint: false, validate: true}, checks)
        assert_raises(Sevgi::ArgumentError) { document.call(unknown: true) }
      end

      private

      def concurrent_documents(name)
        entered = Queue.new
        release = Queue.new
        threads = 2.times.map do
          Thread.new do
            value = PausedValue.new(entered, release)
            Graphics.document(name, attributes: {fill: value})
          end
        end

        2.times { entered.pop }
        2.times { release << true }
        threads.map(&:value)
      ensure
        2.times { release << true } if release
        threads&.each(&:join)
      end

      def racing_registrations(registry, original, name)
        entered = Queue.new
        release = Queue.new
        registry.instance_variable_set(:@available, Gate.new(original, name, entered, release))
        results = Queue.new
        first = profile_registration(registry, name, "red", results)
        entered.pop
        second = profile_registration(registry, name, "blue", results, started = Queue.new)
        started.pop
        Thread.pass while second.alive? && second.status != "sleep"
        release << true
        [first, second].each(&:join)
        2.times.map { results.pop }
      ensure
        release << true
        [first, second].compact.each(&:join)
      end

      def profile_registration(registry, name, fill, results, started = nil)
        profile = Document::Profile.new(name, attributes: {fill:})
        klass = Class.new(Document::Base)
        klass.instance_variable_set(:@profile, profile)

        Thread.new do
          started << true if started
          results << registry.register(name, klass, profile:)
        rescue ::StandardError => e
          results << e
        end
      end
    end

    class DocumentMethodMissingTest < Minitest::Test
      UNRELATED = [Element, Document::Base, Document::Minimal].freeze
      RELATED = [Document::Default, *ObjectSpace.each_object(Class).select { |klass| klass < Document::Default }].freeze

      def setup
        [
          *UNRELATED,
          *RELATED
        ].each { |klass| klass.remove_method(:marker) if klass.method_defined?(:marker) }
      end

      def teardown = setup

      def test_method_missing_cache_class_relations
        UNRELATED.each { |klass| refute_operator(klass, :<=, Document::Default) }
        RELATED.each { |klass| assert_operator(klass, :<=, Document::Default) }
      end

      def test_method_missing_caches_block_elements
        test = self

        SVG(:default) do
          [
            self.class,
            *UNRELATED,
            *RELATED
          ].each { |klass| test.refute(klass.method_defined?(:marker)) }

          marker

          [
            self.class,
            *RELATED,
            *UNRELATED
          ].each { |klass| test.assert(klass.method_defined?(:marker)) }
        end
      end

      def test_method_missing_caches_within_elements
        doc = SVG(:default)

        [
          doc.class,
          *UNRELATED,
          *RELATED
        ].each { |klass| refute(klass.method_defined?(:marker)) }

        doc.Within() { marker }

        [
          doc.class,
          *RELATED,
          *UNRELATED
        ].each { |klass| assert(klass.method_defined?(:marker)) }
      end
    end
  end
end
