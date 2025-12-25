# frozen_string_literal: true

module Sevgi
  module Standard
    module Element
      import(
        Animation:           %i[
          animate
          animateMotion
          animateTransform
          mpath
          set
        ],

        Container:           %i[
          a
          defs
          g
          marker
          mask
          missing-glyph
          pattern
          svg
          switch
          symbol
        ],

        Descriptive:         %i[
          desc
          metadata
          title
        ],

        Filter:              %i[
          feBlend
          feColorMatrix
          feComponentTransfer
          feComposite
          feConvolveMatrix
          feDiffuseLighting
          feDisplacementMap
          feDistantLight
          feDropShadow
          feFlood
          feFuncA
          feFuncB
          feFuncG
          feFuncR
          feGaussianBlur
          feImage
          feMerge
          feMergeNode
          feMorphology
          feOffset
          fePointLight
          feSpecularLighting
          feSpotLight
          feTile
          feTurbulence
        ],

        FilterPrimitive:     %i[
          feBlend
          feColorMatrix
          feComponentTransfer
          feComposite
          feConvolveMatrix
          feDiffuseLighting
          feDisplacementMap
          feDropShadow
          feFlood
          feFuncA
          feFuncB
          feFuncG
          feFuncR
          feGaussianBlur
          feImage
          feMerge
          feMergeNode
          feMorphology
          feOffset
          feSpecularLighting
          feTile
          feTurbulence
        ],

        FilterLightSource:   %i[
          feDistantLight
          fePointLight
          feSpotLight
        ],

        Font:                %i[
          font
          font-face
          font-face-format
          font-face-name
          font-face-src
          font-face-uri
          hkern
          vkern
        ],

        Gradient:            %i[
          linearGradient
          radialGradient
          stop
        ],

        Graphics:            %i[
          circle
          ellipse
          image
          line
          path
          polygon
          polyline
          rect
          text
          use
        ],

        GraphicsReferencing: %i[
          image
          use
        ],

        NeverRendered:       %i[
          clipPath
          defs
          hatch
          linearGradient
          marker
          mask
          metadata
          pattern
          radialGradient
          script
          style
          symbol
          title
        ],

        PaintServer:         %i[
          hatch
          linearGradient
          pattern
          radialGradient
          solidcolor
        ],

        Renderable:          %i[
          a
          circle
          ellipse
          foreignObject
          g
          image
          line
          path
          polygon
          polyline
          rect
          svg
          switch
          symbol
          text
          textPath
          tspan
          use
        ],

        Shape:               %i[
          circle
          ellipse
          line
          path
          polygon
          polyline
          rect
        ],

        ShapeBasic:          %i[
          circle
          ellipse
          line
          polygon
          polyline
          rect
        ],

        Structural:          %i[
          defs
          g
          svg
          symbol
          use
        ],

        Text:                %i[
          glyph
          glyphRef
          text
          textPath
          tref
          tspan
        ],

        TextChild:           %i[
          textPath
          tref
          tspan
        ],

        UnrelatedCommon:     %i[
          a
          clipPath
          color-profile
          cursor
          filter
          font
          font-face
          foreignObject
          image
          marker
          mask
          pattern
          script
          style
          switch
          text
          view
        ],

        # Uncategorized elements (for the sake of completeness)

        Uncategorized:       %i[
          clipPath
          color-profile
          cursor
          filter
          foreignObject
          hatchpath
          script
          style
          view
        ],

        # Deprecated elements

        Deprecated:          %i[
          cursor
          font
          font-face
          font-face-format
          font-face-name
          font-face-src
          font-face-uri
          glyph
          glyphRef
          hkern
          missing-glyph
          tref
          vkern
        ]
      )

      def ignore?(element)
        (name = element.to_s).include?(":") || name.start_with?("_")
      end
    end
  end
end
