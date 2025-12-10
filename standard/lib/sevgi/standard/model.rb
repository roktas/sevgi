# frozen_string_literal: true

module Sevgi
  module Standard
    module Model
      module CDataOnly
        def apply(cdata:, elements:)
          UnallowedElementsError.(element, elements) unless elements.empty?
        end
      end

      module CDataOrSomeElements
        def apply(cdata:, elements:)
          unallowed = elements - spec[:elements]
          UnallowedElementsError.(element, unallowed) unless unallowed.empty?
        end
      end

      module NoneElements
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          UnallowedElementsError.(element, elements) unless elements.empty?
        end
      end

      module SomeElements
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          unallowed = elements - spec[:elements]
          UnallowedElementsError.(element, unallowed) unless unallowed.empty?
        end
      end

      module SpecialFeDiffuseLighting
        # Any number of Descriptive elements and exactly one FilterLightSource element, in any order.
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

      module SpecialFeSpecularLighting
        # Exactly one FilterLightSource element first and any number of Descriptive elements in any order.
        def apply(cdata:, elements:)
          UnallowedCDataError.(element, cdata) if cdata

          unless Element.is?(elements.first, :FilterLightSource)
            UnmetConditionError.(element, "Exactly one FilterLightSource element as first required")
          end

          unless (unallowed = Element.unpick(elements[1..], :Descriptive)).empty?
            UnallowedElementsError.(element, unallowed) unless unallowed.empty?
          end
        end
      end

      module SpecialFontFace
        # Any number of Descriptive elements and at most one font-face element in any order.
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
