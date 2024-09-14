# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Underscore
        def _(*contents)
          Element(:_, *contents)
        end

        def Comment(comment)
          _ Content.verbatim("<!-- #{comment} -->")
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
