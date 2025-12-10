# frozen_string_literal: true

module Sevgi
  module Standard
    module Specification
      import(
        a:                   {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocument
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style
            Xlink

            download
            href
            hreflang
            ping
            referrerpolicy
            rel
            role
            target
            type
          ],

          elements:   %i[
            Animation
            Descriptive
            Gradient
            Shape
            Structural
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        animate:             {
          attributes: %i[
            AnimationAddition
            AnimationAttributeTarget
            AnimationTiming
            AnimationValue
            ConditionalProcessing
            Core
            EventAnimation
            EventDocument
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            href
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        animateMotion:       {
          attributes: %i[
            AnimationAddition
            AnimationAttributeTarget
            AnimationTiming
            AnimationValue
            ConditionalProcessing
            Core
            EventAnimation
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            href
            keyPoints
            origin
            path
            rotate
          ],

          elements:   %i[
            Descriptive

            mpath
          ],

          model:      :SomeElements
        },

        animateTransform:    {
          attributes: %i[
            AnimationAddition
            AnimationAttributeTarget
            AnimationTiming
            AnimationValue
            ConditionalProcessing
            Core
            EventAnimation
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            href
            type
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        circle:              {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            cx
            cy
            pathLength
            r
            role
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        clipPath:            {
          attributes: %i[
            ConditionalProcessing
            Core
            Presentation
            Style

            clipPathUnits
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape

            text
            use
          ],

          model:      :SomeElements
        },

        "color-profile":     {
          attributes: %i[
            Core
            Xlink

            local
            name
            rendering-intent
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        cursor:              {
          attributes: %i[
            ConditionalProcessing
            Core
            Xlink

            externalResourcesRequired
            x
            y
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        defs:                {
          attributes: %i[
            Core
            EventDocument
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style
          ],

          elements:   %i[
            Animation
            Descriptive
            Gradient
            Shape
            Structural
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        desc:                {
          attributes: %i[
            Core
            EventDocument
            EventDocumentElement
            EventGlobal
            Style
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        discard:             {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            Style

            begin
            href
            role
          ],

          elements:   %i[
            Descriptive

            script
          ],

          model:      :SomeElements
        },

        ellipse:             {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            cx
            cy
            pathLength
            role
            rx
            ry
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        feBlend:             {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            in2
            mode
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feColorMatrix:       {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            type
            values
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feComponentTransfer: {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
          ],

          elements:   %i[
            feFuncA
            feFuncR
            feFuncB
            feFuncG
          ],

          model:      :SomeElements
        },

        feComposite:         {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            in2
            k1
            k2
            k3
            k4
            operator
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feConvolveMatrix:    {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            bias
            divisor
            edgeMode
            in
            kernelMatrix
            kernelUnitLength
            order
            preserveAlpha
            targetX
            targetY
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feDiffuseLighting:   {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            diffuseConstant
            in
            kernelUnitLength
            surfaceScale
          ],

          elements:   nil,

          # Any number of Descriptive elements and exactly one FilterLightSource element, in any order.
          model:      :SpecialFeDiffuseLighting
        },

        feDisplacementMap:   {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            in2
            scale
            xChannelSelector
            yChannelSelector
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feDistantLight:      {
          attributes: %i[
            Core
            Style

            azimuth
            elevation
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feDropShadow:        {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            dx
            dy
            in
            stdDeviation
          ],

          elements:   %i[
            animate
            script
            set
          ],

          model:      :SomeElements
        },

        feFlood:             {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feFuncA:             {
          attributes: %i[
            Core
            FilterTransferFunction
            Style
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feFuncB:             {
          attributes: %i[
            Core
            FilterTransferFunction
            Style
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feFuncG:             {
          attributes: %i[
            Core
            FilterTransferFunction
            Style
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feFuncR:             {
          attributes: %i[
            Core
            FilterTransferFunction
            Style
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feGaussianBlur:      {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            edgeMode
            in
            stdDeviation
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feImage:             {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style
            Xlink

            crossorigin
            href
            preserveAspectRatio
          ],

          elements:   %i[
            animate
            animateTransform
            set
          ],

          model:      :SomeElements
        },

        feMerge:             {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style
          ],

          elements:   %i[
            feMergeNode
          ],

          model:      :SomeElements
        },

        feMergeNode:         {
          attributes: %i[
            Core
            Style

            in
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feMorphology:        {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            operator
            radius
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feOffset:            {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            dx
            dy
            in
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        fePointLight:        {
          attributes: %i[
            Core
            Style

            x
            y
            z
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feSpecularLighting:  {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
            kernelUnitLength
            specularConstant
            specularExponent
            surfaceScale
          ],

          elements:   nil,

          # Exactly one FilterLightSource element first and any number of Descriptive elements in any order.
          model:      :SpecialFeSpecularLighting
        },

        feSpotLight:         {
          attributes: %i[
            Core
            Style

            limitingConeAngle
            pointsAtX
            pointsAtY
            pointsAtZ
            specularExponent
            x
            y
            z
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feTile:              {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            in
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        feTurbulence:        {
          attributes: %i[
            Core
            FilterPrimitive
            Presentation
            Style

            baseFrequency
            numOctaves
            seed
            stitchTiles
            type
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        filter:              {
          attributes: %i[
            Core
            Presentation
            Style
            Xlink

            filterRes
            filterUnits
            height
            primitiveUnits
            width
            x
            y
          ],

          elements:   %i[
            Descriptive
            FilterPrimitive

            animate
            set
          ],

          model:      :SomeElements
        },

        font:                {
          attributes: %i[
            Core
            Presentation
            Style

            externalResourcesRequired
            horiz-adv-x
            horiz-origin-x
            horiz-origin-y
            vert-adv-y
            vert-origin-x
            vert-origin-y
          ],

          elements:   %i[
            Descriptive

            font-face
            glyph
            hkern
            missing-glyph
            vkern
          ],

          model:      :SomeElements
        },

        "font-face":         {
          attributes: %i[
            Core

            accent-height
            alphabetic
            ascent
            bbox
            cap-height
            descent
            font-family
            font-size
            font-stretch
            font-style
            font-variant
            font-weight
            hanging
            ideographic
            mathematical
            overline-position
            overline-thickness
            panose-1
            slope
            stemh
            stemv
            strikethrough-position
            strikethrough-thickness
            underline-position
            underline-thickness
            unicode-range
            units-per-em
            v-alphabetic
            v-hanging
            v-ideographic
            v-mathematical
            widths
            x-height
          ],

          elements:   nil,

          # Any number of Descriptive elements and at most one font-face element in any order.
          model:      :SpecialFontFace
        },

        "font-face-format":  {
          attributes: %i[
            Core

            string
          ],

          elements:   nil,

          model:      :NoneElements
        },

        "font-face-name":    {
          attributes: %i[
            Core

            name
          ],

          elements:   nil,

          model:      :NoneElements
        },

        "font-face-src":     {
          attributes: %i[
            Core
          ],

          elements:   %i[
            font-face-name
            font-face-uri
          ],

          model:      :SomeElements
        },

        "font-face-uri":     {
          attributes: %i[
            Core
            Xlink
          ],

          elements:   %i[
            font-face-format
          ],

          model:      :SomeElements
        },

        foreignObject:       {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocument
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            role
            width
            height
            x
            y
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        g:                   {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            role
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        glyph:               {
          attributes: %i[
            Core
            Presentation
            Style

            arabic-form
            d
            glyph-name
            horiz-adv-x
            orientation
            unicode
            vert-adv-y
            vert-origin-x
            vert-origin-y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        glyphRef:            {
          attributes: %i[
            Core
            Presentation
            Style
            Xlink

            dx
            dy
            format
            glyphRef
            x
            y
          ],

          elements:   nil,

          model:      :NoneElements
        },

        hatch:               {
          attributes: %i[
            Core
            EventGlobal
            Presentation
            Style

            hatchContentUnits
            hatchUnits
            href
            pitch
            rotate
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive

            hatchpath
            script
            style
          ],

          model:      :SomeElements
        },

        hatchpath:           {
          attributes: %i[
            Core
            EventGlobal
            Presentation
            Style

            d
            offset
          ],

          elements:   %i[
            Animation
            Descriptive

            script
            style
          ],

          model:      :SomeElements
        },

        hkern:               {
          attributes: %i[
            Core

            g1
            g2
            k
            u1
            u2
          ],

          elements:   nil,

          model:      :NoneElements
        },

        image:               {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style
            Xlink

            crossorigin
            decoding
            height
            href
            preserveAspectRatio
            role
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        line:                {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            pathLength
            role
            x1
            x2
            y1
            y2
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        linearGradient:      {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Presentation
            Style
            Xlink

            gradientTransform
            gradientUnits
            href
            spreadMethod
            x1
            x2
            y1
            y2
          ],

          elements:   %i[
            Descriptive

            animate
            animateTransform
            set
            stop
          ],

          model:      :SomeElements
        },

        marker:              {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Presentation
            Style

            markerHeight
            markerUnits
            markerWidth
            orient
            preserveAspectRatio
            refX
            refY
            viewBox
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        mask:                {
          attributes: %i[
            ConditionalProcessing
            Core
            Presentation
            Style

            height
            maskContentUnits
            maskUnits
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        metadata:            {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        "missing-glyph":     {
          attributes: %i[
            Core
            Presentation
            Style

            d
            horiz-adv-x
            vert-adv-y
            vert-origin-x
            vert-origin-y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        mpath:               {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            href
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        path:                {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            d
            pathLength
            role
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        pattern:             {
          attributes: %i[
            Core
            EventGlobal
            Style
            Presentation
            Xlink

            height
            href
            patternContentUnits
            patternTransform
            patternUnits
            preserveAspectRatio
            viewBox
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        polygon:             {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            pathLength
            points
            role
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        polyline:            {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            pathLength
            points
            role
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        radialGradient:      {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style
            Presentation
            Xlink

            cx
            cy
            fr
            fx
            fy
            gradientTransform
            gradientUnits
            href
            r
            spreadMethod
          ],

          elements:   %i[
            Descriptive

            animate
            animateTransform
            set
            stop
          ],

          model:      :SomeElements
        },

        rect:                {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            height
            pathLength
            role
            rx
            ry
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        script:              {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            crossorigin
            href
            type
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        set:                 {
          attributes: %i[
            AnimationAttributeTarget
            AnimationTiming
            ConditionalProcessing
            Core
            EventAnimation
            EventDocumentElement
            EventGlobal
            Style
            Xlink

            href
            to
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        stop:                {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Presentation
            Style

            offset
          ],

          elements:   %i[
            animate
            set
          ],

          model:      :SomeElements
        },

        style:               {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style

            media
            title
            type
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        svg:                 {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocument
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            baseProfile
            contentScriptType
            contentStyleType
            height
            playbackorder
            preserveAspectRatio
            role
            timelinebegin
            version
            viewBox
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        switch:              {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            role
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape

            a
            foreignObject
            g
            image
            svg
            switch
            text
            use
          ],

          model:      :SomeElements
        },

        symbol:              {
          attributes: %i[
            Aria
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            height
            preserveAspectRatio
            refX
            refY
            role
            viewBox
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
            Shape
            Structural
            Gradient
            UnrelatedCommon
          ],

          model:      :SomeElements
        },

        text:                {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            dx
            dy
            lengthAdjust
            role
            rotate
            textLength
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
            TextChild

            a
          ],

          model:      :CDataOrSomeElements
        },

        textPath:            {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Style
            Presentation
            Xlink

            href
            lengthAdjust
            method
            path
            role
            side
            spacing
            startOffset
            textLength
          ],

          elements:   %i[
            Descriptive

            a
            animate
            set
            tref
            tspan
          ],

          model:      :CDataOrSomeElements
        },

        title:               {
          attributes: %i[
            Core
            EventDocumentElement
            EventGlobal
            Style
          ],

          elements:   nil,

          model:      :CDataOnly
        },

        tref:                {
          attributes: %i[
            ConditionalProcessing
            Core
            EventGraphical
            Presentation
            Style
            Xlink

            externalResourcesRequired
          ],

          elements:   %i[
            Descriptive

            animate
            set
          ],

          model:      :SomeElements
        },

        tspan:               {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style

            dx
            dy
            lengthAdjust
            role
            rotate
            textLength
            x
            y
          ],

          elements:   %i[
            Descriptive

            a
            animate
            set
            tref
            tspan
          ],

          model:      :CDataOrSomeElements
        },

        use:                 {
          attributes: %i[
            Aria
            ConditionalProcessing
            Core
            EventDocumentElement
            EventGlobal
            EventGraphical
            Presentation
            Style
            Xlink

            height
            href
            role
            width
            x
            y
          ],

          elements:   %i[
            Animation
            Descriptive
          ],

          model:      :SomeElements
        },

        view:                {
          attributes: %i[
            Aria
            Core
            EventDocumentElement
            EventGlobal
            Style

            preserveAspectRatio
            role
            viewBox
            viewTarget
            zoomAndPan
          ],

          elements:   %i[
            Descriptive
          ],

          model:      :SomeElements
        },

        vkern:               {
          attributes: %i[
            Core

            u1
            g1
            u2
            g2
            k
          ],

          elements:   nil,

          model:      :NoneElements
        }
      )
    end
  end
end
