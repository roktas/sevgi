# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      DEFAULTS = { lint: true, validate: true }.freeze

      class Proto < Element
        extend Profile::DSL

        mixture Mixtures::Core
        mixture Mixtures::Render

        def call(*, **)
          options = DEFAULTS.merge(**)

          self.Process(*, **options) if respond_to?(:Process)
          self.Render(*, **options)
        end

        class << self
          def attributes = self == Proto ? {} : { **superclass.attributes, **profile.attributes }

          def preambles  = self == Proto ? nil : profile.preambles || superclass.preambles
        end
      end

      class Base < Proto
        public_class_method :new

        document :base

        mixture Mixtures::Duplicate
        mixture Mixtures::Hatch
        mixture Mixtures::Identify
        mixture Mixtures::Lint
        mixture Mixtures::Replicate
        mixture Mixtures::Save
        mixture Mixtures::Transform
        mixture Mixtures::Underscore
        mixture Mixtures::Validate
        mixture Mixtures::Wrappers

        def Process(**options)
          self.Validate if options[:validate]
          self.Lint     if options[:lint]
        end
      end
    end
  end
end
