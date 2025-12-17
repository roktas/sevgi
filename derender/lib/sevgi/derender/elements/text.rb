#!/usr/bin/env ruby
# frozen_string_literal: true

module Sevgi
  module Derender
    module Elements
      module Text
        def compile(*) = [ "_ #{content}" ]
      end
    end
  end
end
