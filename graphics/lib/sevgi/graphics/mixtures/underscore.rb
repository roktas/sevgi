# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Underscore
        def _(*contents)
          self.class.call(:_, parent: self, contents:)
        end

        def Ancestral
          {}.tap do |result|
            Root.Traverse { |element| result.merge!(element[:_]) if element.has?(:_) }
          end
        end
      end
    end
  end
end
