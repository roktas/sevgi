# frozen_string_literal: true

require "erb"

module Sevgi
  module Derender
    module Template
      module Data
        Css = <<~'ERB'
          <%- content.each do |selector, declarations| %>
            css[<%= selector.inspect %>] = {
              <%- declarations.each do |key, value| -%>
                <%= key.to_key %>: <%= value.to_value %>,
              <%- end -%>
            }
          <%- end -%>
        ERB

        Element = <<~'ERB'
          <%- if children.any? -%>
            <%- if children.count == 1 and children.first.node.text? -%>
              <%- if attributes.any? -%>
                <%= name %> "<%= content %>", <%= Attribute.render(attributes) %>
              <%- else -%>
                <%= name %> "<%= content %>"
              <%- end -%>
            <%- else -%>
              <%= name %> <%= Attribute.render(attributes) %> do
                <%- children.each do |child| -%>
                  <%= child.ruby %>
                <%- end -%>
              end
            <%- end -%>
          <%- else -%>
            <%= name %> <%= Attribute.render(attributes) %>
          <%- end -%>
        ERB

        Root = <<~'ERB'
          <%- if preambles.any? -%>
          Doc preambles: [
            <%- preambles.each do |preamble| -%>
            '<%= preamble %>',
            <%- end -%>
          ]
          <%- end -%>

          <%- if children.any? -%>
            <%- if children.count == 1 and children.first.node.text? -%>
              <%- if attributes.any? -%>
                SVG <%= Attribute.render(attributes, namespaces) %>
              <%- else -%>
                SVG
              <%- end -%>
            <%- else -%>
              SVG <%= Attribute.render(attributes, namespaces) %> do
                <%- children.each do |child| -%>
                  <%= child.ruby %>
                <%- end -%>
              end
            <%- end -%>
          <%- else -%>
            SVG <%= Attribute.render(attributes, namespaces) %>
          <%- end -%>
        ERB

        Text = <<~'ERB'
          _ "<%= content %>"
        ERB

        extend self
      end

      def self.render(type, binding) = ERB.new(Data.const_get(type), trim_mode: "%-").result(binding)
    end
  end
end
