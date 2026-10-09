#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "fileutils"
require "sevgi/graphics"
require "sevgi/sundries"

directory = File.expand_path("../../../.local/mainz", __dir__)
FileUtils.mkdir_p(directory)

documents = 4.times.map do |index|
  Sevgi::Graphics.SVG(width: 20, height: 20) do
    g(id: "ink#{index}") do
      rect(width: 10, height: 10, fill: "none", stroke: "black")
    end

    Style do
      Target("ink", selectors: ["#ink#{index}"])
      Param(
        "display",
        targets: ["ink"],
        property: "display",
        schema: {type: "string", enum: %w[inline none]}
      )
      Param(
        "opacity",
        targets: ["ink"],
        property: "stroke-opacity",
        schema: {type: "number", minimum: 0, maximum: 1}
      )
      Group("Ink", parameters: ["opacity"])
      Profiles(
        "print",
        name: "Printer",
        parameters: ["opacity"],
        profiles: [
          {id: "original", name: "Original", overrides: {}},
          {id: "light", name: "Light", overrides: {opacity: 0.4}}
        ]
      )
    end
  end
end

outputs = documents
  .each_with_index
  .map do |document, index|
    Thread.new { document.PDF(File.join(directory, "drawing#{index}.pdf"), fallback: false) }
  end
  .map(&:value)

native_gems = $LOADED_FEATURES.grep(%r{/(?:cairo|rsvg2|hexapdf)(?:[/.])})
raise "Prepared export loaded ordinary export gems: #{native_gems}" unless native_gems.empty?

identity = Sevgi::Sundries::Mainz.fingerprint
raise "Unexpected Mainz runtime report" unless identity.fetch("runtime").fetch("contract") == 1
outputs.each do |output|
  Sevgi::F.sh!("qpdf", "--check", output)
  report = JSON.parse(Sevgi::F.sh!("mainz", "verify", output).out)
  raise "Invalid prepared PDF" unless report.fetch("valid")
end

require "hexapdf"

outputs.each do |output|
  document = HexaPDF::Document.open(output)
  raise "Wrong PDF dimensions" unless document.pages.first.box.width == 15
  files = document.catalog[:Names][:EmbeddedFiles].each_entry.to_h
  manifest = JSON.parse(files.fetch("mainz.json")[:EF][:F].stream)
  raise "Missing paint controls" unless manifest.fetch("parameters").keys.sort == %w[display opacity]
  profiles = manifest.fetch("profileSets").first.fetch("profiles")
  raise "Wrong profile overrides" unless profiles.last.fetch("overrides") == {"opacity" => 0.4}
end

puts(JSON.generate(parallel_documents: outputs.size, native_export_gems_loaded: native_gems, runtime: identity))
