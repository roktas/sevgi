# Frozen_string_literal: true

require_relative "derender/css"
require_relative "derender/document"
require_relative "derender/node"
require_relative "derender/template"

module Sevgi
  module Derender
    def derender_file(file, id) = Document.load_file(file).(id)

    def derender(content, id)   = Document.new(content).(id)

    extend self
  end
end
