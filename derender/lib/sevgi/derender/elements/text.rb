#!/usr/bin/env ruby
# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Text
        def decompile(*) = [ "_ #{content}" ]
      end
    end
  end
end
