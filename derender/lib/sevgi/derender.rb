# Frozen_string_literal: true

require_relative "derender/internal"

require_relative "derender/document"
require_relative "derender/node"
require_relative "derender/render"

module Sevgi
  module Derender
    def derender_file(file, id = nil) = Document.load_file(file).(id)

    def derender(content, id = nil)   = Document.new(content).(id)

    extend self
  end
end
