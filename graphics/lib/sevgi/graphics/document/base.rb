# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      # Abstract common document layer with the profile-independent DSL mixture set. It is not registered as a
      # selectable profile. Advanced extensions may target this class through {Sevgi::Graphics::Mixtures.mixin}; doing
      # so changes every descendant profile process-wide. Derive scoped custom profiles from {Minimal} instead.
      class Base < Proto
        document nil, register: false

        mixture :Call
        mixture :Duplicate
        mixture :Export
        mixture :Identify
        mixture :Include
        mixture :Lint
        mixture :Save
        mixture :Tile
        mixture :Transform
        mixture :Underscore
        mixture :Validate

        # Runs pre-render validation and lint checks.
        # @param options [Hash] pre-render options
        # @option options [Boolean] :validate run SVG standard validation
        # @option options [Boolean] :lint run document lint checks
        # @return [void]
        # @raise [Sevgi::ValidationError] when validation fails
        # @raise [Sevgi::Graphics::LintError] when linting fails
        def PreRender(**options)
          self.Validate() if options[:validate]
          self.Lint() if options[:lint]
        end
      end
    end
  end
end
