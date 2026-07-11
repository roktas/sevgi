# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class PaperTest < Minitest::Test
      def test_define_allows_profile_overwrite
        _, stderr = capture_io do
          Paper.define(:paper_test_card, width: 3, height: 5)
          Paper.define(:paper_test_card, width: 7, height: 11)
        end

        assert_empty(stderr)
        assert_equal([7.0, 11.0, :mm, :paper_test_card], Paper.paper_test_card.deconstruct)
      end

      def test_define_rejects_reserved_methods
        error = assert_raises(ArgumentError) do
          Paper.define(:define, width: 3, height: 5)
        end

        assert_match(/\breserved\b/, error.message)
        assert_instance_of(::Method, Paper.method(:define))
      end

      def test_invalid_inputs_raise_sevgi_argument_error
        [
          -> { Paper["wide", 5] },
          /\bwidth\b/,
          -> { Paper[3, "tall"] },
          /\bheight\b/,
          -> { Paper[3, 5, Object.new] },
          /\bunit\b/,
          -> { Paper[3, 5, :mm, Object.new] },
          /\bname\b/,
          -> { Paper.define(Object.new, width: 3, height: 5) },
          /\bname\b/
        ].each_slice(2) do |operation, message|
          error = assert_raises(Sevgi::ArgumentError, &operation)

          assert_match(message, error.message)
        end
      end

      def test_dimensions_require_finite_positive_real_numbers
        [
          -> { Paper["3", 5] },
          -> { Paper[Complex(3, 1), 5] },
          -> { Paper[Float::NAN, 5] },
          -> { Paper[Float::INFINITY, 5] },
          -> { Paper[0, 5] },
          -> { Paper[-1, 5] },
          -> { Paper[3, 0] },
          -> { Paper[3, -1] }
        ].each { |operation| assert_raises(Sevgi::ArgumentError, &operation) }
      end

      def test_symbol_inputs_reject_invalid_converters
        raising = Object.new.tap { it.define_singleton_method(:to_sym) { raise "broken" } }
        wrong = Object.new.tap { it.define_singleton_method(:to_sym) { "paper" } }

        [raising, wrong].each do |value|
          [
            -> { Paper[3, 5, value] },
            -> { Paper[3, 5, :mm, value] },
            -> { Paper.define(value, width: 3, height: 5) }
          ].each do |operation|
            assert_raises(Sevgi::ArgumentError, &operation)
          end

          refute(Paper.exist?(value))
        end
      end

      def test_define_validates_before_replacing_profile
        name = :paper_atomic_card
        original = Paper.define(name, width: 3, height: 5)
        ghost = :paper_invalid_ghost
        invalid = [
          -> { Paper.define(name, width: "wide", height: 7) },
          -> { Paper.define(name, width: 7, height: 11, typo: true) },
          -> { Paper.define(ghost, width: 7, height: 11, typo: true) },
          -> { Paper.new(width: 7, height: 11, typo: true) }
        ]

        invalid.each { |operation| assert_raises(Sevgi::ArgumentError, &operation) }

        assert_same(original, Paper.public_send(name))
        assert(Paper.exist?(name))
        refute(Paper.exist?(ghost))
        refute_respond_to(Paper, ghost)
      end

      def test_define_supports_non_identifier_profile_names
        ["paper-card", "paper card", "1paper"].each do |name|
          profile = Paper.define(name, width: 3, height: 5)

          assert_same(profile, Paper.public_send(name))
          assert(Paper.exist?(name))
          assert_equal(name.to_sym, profile.name)
        end
      end

      def test_comparison_returns_nil_for_incompatible_objects
        smaller = Paper[3, 5]
        larger = Paper[7, 11]

        assert_nil(smaller <=> Object.new)
        assert_equal([smaller, larger], [larger, smaller].sort)
      end

      def test_iso_a_profiles_use_standard_small_sizes
        [
          [74.0, 105.0, :mm, :a7],
          Paper.a7.deconstruct,
          [52.0, 74.0, :mm, :a8],
          Paper.a8.deconstruct,
          [37.0, 52.0, :mm, :a9],
          Paper.a9.deconstruct,
          [26.0, 37.0, :mm, :a10],
          Paper.a10.deconstruct
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
