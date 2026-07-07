# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Base
        # @overload Save(*args, **kwargs)
        #   Redirects showcase saves to stdout during passive integration tests.
        #   @param args [Array<Object>] ignored save arguments
        #   @param kwargs [Hash] render options
        #   @return [Object] F.out return value
        #   @api private
        def Save(*, **) = Out(**)

        # @overload Save!(*args, **kwargs)
        #   Redirects forced showcase saves to stdout during passive integration tests.
        #   @param args [Array<Object>] ignored save arguments
        #   @param kwargs [Hash] render options
        #   @return [Object] F.out return value
        #   @api private
        def Save!(...) = Save(...)
      end
    end
  end
end
