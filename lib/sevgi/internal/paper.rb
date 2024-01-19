# frozen_string_literal: true

module Sevgi
  Paper = {
    a3:        Dim[297.0, 420.0],
    a4:        Dim[210.0, 297.0],
    a5:        Dim[148.5, 210.0],
    a6:        Dim[105.0, 148.5],
    a7:        Dim[74.25, 105.0],
    b3:        Dim[353.0, 500.0],
    b4:        Dim[250.0, 353.0],
    b5:        Dim[176.5, 250.0],
    b6:        Dim[125.0, 176.5],
    b7:        Dim[88.25, 125.0],
    large:     Dim[130.0, 210.0],
    passport:  Dim[88.0,  125.0],
    pocket:    Dim[90.0,  140.0],
    travelers: Dim[110.0, 210.0],
    us:        Dim[215.9, 279.4],
    xlarge:    Dim[190.0, 250.0]
  }.tap do
    def _1.default_proc = proc { |_, key| ArgumentError.("No such paper: #{key}") }

    def _1.default      = :a4
  end.freeze
end
