# frozen_string_literal: true

module Sevgi
  module Derender
    # Element strategy modules mixed into derender nodes according to XML node type.
    # @api private
    module Elements
    end
  end
end

require_relative "elements/any"
require_relative "elements/comment"
require_relative "elements/instruction"
require_relative "elements/css"
require_relative "elements/root"
require_relative "elements/text"
