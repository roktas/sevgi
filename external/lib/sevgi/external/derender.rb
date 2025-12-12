# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module External
    def Derender(...) = Derender.derender_file(...)
  end
end
