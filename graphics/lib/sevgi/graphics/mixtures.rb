# frozen_string_literal: true

module Sevgi
  module Graphics
    # Mixins that extend document classes with DSL helper methods.
    module Mixtures
      # @overload mixin(mod, document = Graphics::Document::Base, &block)
      #   Includes a named mixture and optional anonymous extension into a document class.
      #   @param mod [Symbol, String] mixture constant name
      #   @param document [Class] document class receiving the mixture
      #   @yield defines methods in the anonymous mixture
      #   @yieldreturn [Object] ignored module-definition result
      #   @return [Module, nil] optional anonymous mixture when a block is given
      #   @raise [NameError] when the mixture does not exist
      # @overload mixin(document = Graphics::Document::Base, &block)
      #   Includes only an anonymous extension into a document class.
      #   @param document [Class] document class receiving the mixture
      #   @yield defines methods in the anonymous mixture
      #   @yieldreturn [Object] ignored module-definition result
      #   @return [Module] anonymous mixture
      #   @raise [Sevgi::ArgumentError] when no named mixture or block is given
      def self.mixin(mod = Undefined, document = Graphics::Document::Base, &block)
        mod, document = normalize(mod, document, block)
        ArgumentError.("Mixture name or block required") if mod == Undefined && !block

        document.send(:mixture, mod) unless mod == Undefined
        include_anonymous(document, &block) if block
      end

      class << self
        private

        def anonymous_document?(mod, block)
          block && mod.is_a?(::Class) && mod <= Graphics::Document::Proto
        end

        def include_anonymous(document, &block)
          ::Module.new(&block).tap do |anonymous|
            document.send(:include, anonymous)
            document.extend(anonymous.const_get(:ClassMethods)) if anonymous.const_defined?(:ClassMethods, false)
          end
        end

        def normalize(mod, document, block)
          anonymous_document?(mod, block) ? [Undefined, mod] : [mod, document]
        end
      end
    end
  end
end

require_relative "mixtures/core"

require_relative "mixtures/call"
require_relative "mixtures/duplicate"
require_relative "mixtures/export"
require_relative "mixtures/hatch"
require_relative "mixtures/identify"
require_relative "mixtures/include"
require_relative "mixtures/inkscape"
require_relative "mixtures/lint"
require_relative "mixtures/polyfills"
require_relative "mixtures/rdf"
require_relative "mixtures/render"
require_relative "mixtures/save"
require_relative "mixtures/symbols"
require_relative "mixtures/tile"
require_relative "mixtures/transform"
require_relative "mixtures/underscore"
require_relative "mixtures/validate"
require_relative "mixtures/wrappers"
