# frozen_string_literal: true

require "erb"

module Sevgi
  module Derender
    module Render
      module Template
        module Data
          Css = <<~'ERB'
            css(<%= Render.css(content) %>)
          ERB

          Element = <<~'ERB'
            <%- if children.any? -%>
              <%- if children.count == 1 and children.first.node.text? -%>
                <%- if attributes.any? -%>
                  <%= name %> "<%= content %>", <%= Render.attributes(attributes) %>
                <%- else -%>
                  <%= name %> "<%= content %>"
                <%- end -%>
              <%- else -%>
                <%= name %> <%= Render.attributes(attributes) %> do
                  <%- children.each do |child| -%>
                    <%= child.ruby %>
                  <%- end -%>
                end
              <%- end -%>
            <%- else -%>
              <%= name %> <%= Render.attributes(attributes) %>
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
                  SVG <%= Render.attributes(attributes, namespaces) %>
                <%- else -%>
                  SVG
                <%- end -%>
              <%- else -%>
                SVG <%= Render.attributes(attributes, namespaces) %> do
                  <%- children.each do |child| -%>
                    <%= child.ruby %>
                  <%- end -%>
                end
              <%- end -%>
            <%- else -%>
              SVG <%= Render.attributes(attributes, namespaces) %>
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
end
