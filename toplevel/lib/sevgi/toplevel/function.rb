# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Toplevel
    module Function
      extend Sevgi::Function::Color
      extend Sevgi::Function::Math
      extend Sevgi::Function::Pluralize
      extend Sevgi::Function::Shell
      extend Sevgi::Function::UI
    end

    Promote Function, :F
  end
end
