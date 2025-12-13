# frozen_string_literal: true

module Sevgi
  module Derender
    module Template
      def css = <<~ERB
        <%= "# :css" if ENV['DEBUG'] -%>
        <%- content.each do |selector, declarations| %>
        css[<%= selector.inspect %>] = {
          <%- declarations.each do |key, value| -%>
          <%= key.to_key %>: <%= value.to_value %>,
          <%- end -%>}
        <%- end -%>
      ERB

      def element = <<~ERB
        <%= "# :element" if ENV['DEBUG'] -%>
        <%- if children.any? -%>
          <%- if children.count == 1 and children.first.node.text? -%>
            <%- if attributes.any? -%>
        <%= name %> "<%= content %>", <%= CSS.(attributes) %>
            <%- else -%>
        <%= name %> "<%= content %>"
            <%- end -%>
          <%- else -%>
        <%= name %> <%= CSS.(attributes) %> do
            <%- children.each do |child| -%>
        <%= child.ruby %>
            <%- end -%>
        end
          <%- end -%>
        <%- else -%>
        <%= name %> <%= CSS.(attributes) %>
        <%- end -%>
      ERB

      def root = <<~ERB
        <%= "# :root" if ENV['DEBUG'] -%>

        require "sevgi"

        SVG do
        <%- children.each do |child| -%>
        <%= child.Render %>
        <%- end -%>
        end
      ERB

      def text = <<~ERB
        <%= "# :text" if ENV['DEBUG'] -%>
        _ "<%= content %>"
      ERB

      def [](type) = public_send(type)

      extend self
    end
  end
end
