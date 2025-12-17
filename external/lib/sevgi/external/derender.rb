# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module External
    def Derender(file, id)  = Derender.derender_file(file, id:)

    def Derender!(file, id) = Derender.derender_file!(file, id:)
  end
end
