# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module Toplevel
    def Decompile(file, id)  = Derender.decompile_file(file, id:)

    def Decompile!(file, id) = Derender.decompile_file!(file, id:)

    def Derender(file, id)   = Derender.derender_file(file, id:)

    def Derender!(file, id)  = Derender.derender_file!(file, id:)
  end
end
