# Frozen_string_literal: true

require_relative "derender/refinements"
require_relative "derender/css"
require_relative "derender/node"
require_relative "derender/document"

module Sevgi
  module Derender
    def call(file, id) = Document.load_file(file).(id)

    extend self
  end
end
