# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    module Document
      class Test < Base
        document :test, attributes: { "data-var": "xxx" }
      end
    end

    class DocumentProfileTest < Minitest::Test
      DOC = :test

      def test_subclass_root_attributes_doesnt_leak
        expected = <<~SVG.chomp
          <svg data-var="xxx">
            <line data-var="main var"/>
            <line data-var="duplicated var"/>
          </svg>
        SVG

        actual = SVG DOC do
          line("data-var": "main var").Duplicate[:"data-var"] = "duplicated var"
        end.Render

        assert_equal(expected, actual)
      end

      def test_subclass_works_with_default_canvas
        expected = <<~SVG.chomp
          <svg data-var="xxx" width="210.0mm" height="297.0mm" viewBox="0 0 210 297"/>
        SVG

        actual = SVG(DOC, Canvas(:a4)).Render

        assert_equal(expected, actual)
      end

      def test_subclass_works_with_custom_canvas
        expected = <<~SVG.chomp
          <svg data-var="xxx" width="210.0mm" height="297.0mm" viewBox="-5 -3 210 297"/>
        SVG

        actual = SVG(DOC, Canvas(:a4, margins: [ 3, 5 ])).Render

        assert_equal(expected, actual)
      end
    end

    class DocumentMethodMissingTest < Minitest::Test
      UNRELATED = [ Element, Document::Base, Document::Minimal ].freeze
      RELATED   = [ Document::Default, *ObjectSpace.each_object(Class).select { |klass| klass < Document::Default } ]

      def setup
        [
          *UNRELATED,
          *RELATED
        ].each { |klass| klass.remove_method(:marker) if klass.method_defined?(:marker) }
      end

      def teardown = setup

      def test_class_relations
        UNRELATED.each { |klass| refute_operator(klass, :<=, Document::Default) }
        RELATED.each   { |klass| assert_operator(klass, :<=, Document::Default) }
      end

      def test_method_missing_caching_with_block
        test = self

        SVG :default do
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

      def test_method_missing_caching_with_using_within
        doc = SVG :default

        [
          doc.class,
          *UNRELATED,
          *RELATED
        ].each { |klass| refute(klass.method_defined?(:marker)) }

        doc.Within { marker }

        [
          doc.class,
          *RELATED,
          *UNRELATED
        ].each { |klass| assert(klass.method_defined?(:marker)) }
      end
    end
  end
end
