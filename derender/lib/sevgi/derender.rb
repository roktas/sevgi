# Frozen_string_literal: true

require_relative "derender/internal"

require_relative "derender/attributes"
require_relative "derender/document"
require_relative "derender/elements"
require_relative "derender/node"

module Sevgi
  module Derender
    def decompile(content, id: nil)            = Document.new(content).decompile(id)
    def decompile_file(file, id: nil)          = Document.load_file(file).decompile(id)

    def derender(content, id: nil)             = Document.new(content).decompile(id).derender
    def derender_file(file, id: nil)           = Document.load_file(file).decompile(id).derender

    def evaluate!(content, element, id: nil)   = Document.new(content).decompile(id).evaluate!(element)
    def evaluate(content, element, id: nil)    = Document.new(content).decompile(id).evaluate(element)

    def evaluate_file!(file, element, id: nil) = Document.load_file(file).decompile(id).evaluate!(element)
    def evaluate_file(file, element, id: nil)  = Document.load_file(file).decompile(id).evaluate(element)

    extend self
  end
end
