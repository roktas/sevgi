# frozen_string_literal: true

require_relative "render/attributes"
require_relative "render/css"
require_relative "render/template"

module Sevgi
  module Derender
    module Render
      def attributes(...) = Attributes.render(...)

      def css(...)        = CSS.render(...)

      def template(...)   = Template.render(...)

      extend self
    end
  end
end
