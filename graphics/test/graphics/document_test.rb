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

      def test_class_document_rejects_conflicting_profile
        error = assert_raises(ArgumentError) do
          Class.new(Document::Base) { document(:test, attributes: {"data-var": "conflict"}) }
        end

        assert_match(/\btest\b/, error.message)
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
