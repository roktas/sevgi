# frozen_string_literal: true

module Sevgi
  module Standard
    # SVG content model validators used by {Conform}.
    # @api private
    module Model
      # Validates elements that allow only character data.
      module CDataOnly
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedElementsError] when child elements are present
        def apply(cdata:, elements:)
          _cdata = cdata

          UnallowedElementsError.(element, elements) unless elements.empty?
        end
      end

      # Validates elements that allow character data or selected child elements.
      module CDataOrSomeElements
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedElementsError] when unallowed child elements are present
        def apply(cdata:, elements:)
          _cdata = cdata

          unallowed = elements - spec[:elements]
          UnallowedElementsError.(element, unallowed) unless unallowed.empty?
        end
      end

      # Validates empty elements.
      module NoneElements
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedCDataError] when character data is present
        # @raise [Sevgi::UnallowedElementsError] when child elements are present
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          UnallowedElementsError.(element, elements) unless elements.empty?
        end
      end

      # Validates elements that allow selected child elements but no character data.
      module SomeElements
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedCDataError] when character data is present
        # @raise [Sevgi::UnallowedElementsError] when unallowed child elements are present
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          unallowed = elements - spec[:elements]
          UnallowedElementsError.(element, unallowed) unless unallowed.empty?
        end
      end

      # Validates the special `feDiffuseLighting` content model.
      module SpecialFeDiffuseLighting
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedCDataError] when character data is present
        # @raise [Sevgi::UnallowedElementsError] when unallowed child elements are present
        # @raise [Sevgi::UnmetConditionError] when required light source elements are absent
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          unless (filter_light_source_elements = Element.pick(elements, :FilterLightSource)).size == 1
            UnmetConditionError.(element, "Exactly one FilterLightSource element required")
          end

          unless (unallowed = Element.unpick(elements - filter_light_source_elements, :Descriptive)).empty?
            UnallowedElementsError.(element, unallowed)
          end
        end
      end

      # Validates the special `feSpecularLighting` content model.
      module SpecialFeSpecularLighting
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedCDataError] when character data is present
        # @raise [Sevgi::UnallowedElementsError] when unallowed child elements are present
        # @raise [Sevgi::UnmetConditionError] when the first child is not a light source
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          unless Element.is?(elements.first, :FilterLightSource)
            UnmetConditionError.(element, "Exactly one FilterLightSource element as first required")
          end

          unless (unallowed = Element.unpick(elements[1..], :Descriptive)).empty?
            UnallowedElementsError.(element, unallowed)
          end
        end
      end

      # Validates the special `font-face` content model.
      module SpecialFontFace
        # Applies this content model.
        # @param cdata [String, nil] character data content
        # @param elements [Array<Symbol>] child element names
        # @return [nil]
        # @raise [Sevgi::UnallowedCDataError] when character data is present
        # @raise [Sevgi::UnallowedElementsError] when unallowed child elements are present
        # @raise [Sevgi::UnmetConditionError] when more than one `font-face` child is present
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          if (font_face_elements = elements.select { |element| element == :"font-face" }).size > 1
            UnmetConditionError.(element, "At most one font-face element allowed")
          end

          unless (unallowed = Element.unpick(elements - font_face_elements, :Descriptive)).empty?
            UnallowedElementsError.(element, unallowed)
          end
        end
      end
    end
  end
end
