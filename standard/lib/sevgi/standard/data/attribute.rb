# frozen_string_literal: true

module Sevgi
  module Standard
    module Attribute
      import(
        Animation:                %i[
          accelerate
          accumulate
          additive
          attributeName
          attributeType
          autoReverse
          begin
          by
          calcMode
          decelerate
          dur
          end
          fill
          from
          keySplines
          keyTimes
          max
          min
          onbegin
          onend
          onrepeat
          repeatCount
          repeatDur
          restart
          to
          values
        ],

        AnimationAddition:        %i[
          accumulate
          additive
        ],

        AnimationAttributeTarget: %i[
          attributeName
          attributeType
        ],

        AnimationValue:           %i[
          accelerate
          autoReverse
          by
          calcMode
          decelerate
          from
          keySplines
          keyTimes
          to
          values
        ],

        AnimationTiming:          %i[
          begin
          dur
          end
          fill
          max
          min
          repeatCount
          repeatDur
          restart
        ],

        Aria:                     %i[
          aria-activedescendant
          aria-atomic
          aria-autocomplete
          aria-busy
          aria-checked
          aria-colcount
          aria-colindex
          aria-colspan
          aria-controls
          aria-current
          aria-describedby
          aria-details
          aria-disabled
          aria-dropeffect
          aria-errormessage
          aria-expanded
          aria-flowto
          aria-grabbed
          aria-haspopup
          aria-hidden
          aria-invalid
          aria-keyshortcuts
          aria-label
          aria-labelledby
          aria-level
          aria-live
          aria-modal
          aria-multiline
          aria-multiselectable
          aria-orientation
          aria-owns
          aria-placeholder
          aria-posinset
          aria-pressed
          aria-readonly
          aria-relevant
          aria-required
          aria-roledescription
          aria-rowcount
          aria-rowindex
          aria-rowspan
          aria-selected
          aria-setsize
          aria-sort
          aria-valuemax
          aria-valuemin
          aria-valuenow
          aria-valuetext
        ],

        ConditionalProcessing:    %i[
          requiredExtensions
          requiredFeatures
          systemLanguage
        ],

        Core:                     %i[
          autofocus
          id
          lang
          tabindex
          xml:base
          xml:lang
          xml:space
        ],

        EventAnimation:           %i[
          onbegin
          onend
          onrepeat
        ],

        EventDocument:            %i[
          onabort
          onerror
          onresize
          onscroll
          onunload
        ],

        EventDocumentElement:     %i[
          oncopy
          oncut
          onpaste
        ],

        EventGlobal:              %i[
          oncancel
          oncanplay
          oncanplaythrough
          onchange
          onclick
          onclose
          oncuechange
          ondblclick
          ondrag
          ondragend
          ondragenter
          ondragleave
          ondragover
          ondragstart
          ondrop
          ondurationchange
          onemptied
          onended
          onerror
          onfocus
          oninput
          oninvalid
          onkeydown
          onkeypress
          onkeyup
          onload
          onloadeddata
          onloadedmetadata
          onloadstart
          onmousedown
          onmouseenter
          onmouseleave
          onmousemove
          onmouseout
          onmouseover
          onmouseup
          onmousewheel
          onpause
          onplay
          onplaying
          onprogress
          onratechange
          onreset
          onresize
          onscroll
          onseeked
          onseeking
          onselect
          onshow
          onstalled
          onsubmit
          onsuspend
          ontimeupdate
          ontoggle
          onvolumechange
          onwaiting
        ],

        EventGraphical:           %i[
          onactivate
          onfocusin
          onfocusout
        ],

        FilterPrimitive:          %i[
          height
          result
          width
          x
          y
        ],

        FilterTransferFunction:   %i[
          amplitude
          exponent
          intercept
          offset
          slope
          tableValues
          type
        ],

        Presentation:             %i[
          alignment-baseline
          baseline-shift
          clip
          clip-path
          clip-rule
          color
          color-interpolation
          color-interpolation-filters
          color-profile
          color-rendering
          cursor
          direction
          display
          dominant-baseline
          enable-background
          fill
          fill-opacity
          fill-rule
          filter
          flood-color
          flood-opacity
          font-family
          font-size
          font-size-adjust
          font-stretch
          font-style
          font-variant
          font-weight
          glyph-orientation-horizontal
          glyph-orientation-vertical
          image-rendering
          kerning
          letter-spacing
          lighting-color
          marker-end
          marker-mid
          marker-start
          mask
          opacity
          overflow
          pointer-events
          shape-rendering
          stop-color
          stop-opacity
          stroke
          stroke-dasharray
          stroke-dashoffset
          stroke-linecap
          stroke-linejoin
          stroke-miterlimit
          stroke-opacity
          stroke-width
          text-anchor
          text-decoration
          text-rendering
          transform
          transform-origin
          unicode-bidi
          vector-effect
          visibility
          word-spacing
          writing-mode
        ],

        Style:                    %i[
          class
          style
        ],

        Xlink:                    %i[
          xlink:actuate
          xlink:arcrole
          xlink:href
          xlink:role
          xlink:show
          xlink:title
          xlink:type
        ],

        # Uncategorized attributes (for the sake of completeness)

        Uncategorized:            %i[
          accent-height
          alphabetic
          arabic-form
          ascent
          azimuth
          baseFrequency
          baseProfile
          bbox
          bias
          cap-height
          clipPathUnits
          contentScriptType
          contentStyleType
          crossorigin
          cx
          cy
          d
          decoding
          descent
          diffuseConstant
          divisor
          download
          dx
          dy
          edgeMode
          elevation
          externalResourcesRequired
          filterRes
          filterUnits
          format
          fr
          fx
          fy
          g1
          g2
          glyph-name
          glyphRef
          gradientTransform
          gradientUnits
          hanging
          hatchContentUnits
          hatchUnits
          horiz-adv-x
          horiz-origin-x
          horiz-origin-y
          href
          hreflang
          ideographic
          in
          in2
          k
          k1
          k2
          k3
          k4
          kernelMatrix
          kernelUnitLength
          keyPoints
          lengthAdjust
          limitingConeAngle
          local
          markerHeight
          markerUnits
          markerWidth
          maskContentUnits
          maskUnits
          mathematical
          media
          method
          mode
          name
          numOctaves
          operator
          order
          orient
          orientation
          origin
          overline-position
          overline-thickness
          panose-1
          path
          pathLength
          patternContentUnits
          patternTransform
          patternUnits
          ping
          pitch
          playbackorder
          points
          pointsAtX
          pointsAtY
          pointsAtZ
          preserveAlpha
          preserveAspectRatio
          primitiveUnits
          r
          radius
          refX
          refY
          referrerpolicy
          rel
          rendering-intent
          role
          rotate
          rx
          ry
          scale
          seed
          side
          spacing
          specularConstant
          specularExponent
          spreadMethod
          startOffset
          stdDeviation
          stemh
          stemv
          stitchTiles
          strikethrough-position
          strikethrough-thickness
          string
          surfaceScale
          target
          targetX
          targetY
          textLength
          timelinebegin
          title
          u1
          u2
          underline-position
          underline-thickness
          unicode
          unicode-range
          units-per-em
          v-alphabetic
          v-hanging
          v-ideographic
          v-mathematical
          version
          vert-adv-y
          vert-origin-x
          vert-origin-y
          viewBox
          viewTarget
          widths
          x-height
          x1
          x2
          xChannelSelector
          y1
          y2
          yChannelSelector
          z
          zoomAndPan
        ],

        # Deprecated attributes

        Deprecated:               %i[
          accent-height
          alphabetic
          amplitude
          arabic-form
          ascent
          attributeType
          baseProfile
          bbox
        ]
      )

      def ignore?(attribute)
        attribute.start_with?("_")                                                                           ||
        attribute == :xmlns                                                                                  ||
        attribute.start_with?("data-")                                                                       ||
        (attribute.to_s.include?(":") && !attribute.start_with?("xlink:") && !attribute.start_with?("xml:"))
      end
    end
  end
end
