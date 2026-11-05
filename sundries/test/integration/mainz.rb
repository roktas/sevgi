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

    Imprint do
      Page name: "Sheet #{index + 1}", tags: ["practice"]
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

metadata = Sevgi::Graphics.SVG(width: 20, height: 20) do
  rect width: 10, height: 10, fill: "black"
  Imprint do
    Page name: "Reference", tags: ["details"]
  end
end
image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC".unpack1("m0")
metadata_output = metadata.PDF(File.join(directory, "metadata.pdf"), preview: image, fallback: false)

outputs = documents
  .each_with_index
  .map do |document, index|
    Thread.new { document.PDF(File.join(directory, "drawing#{index}.pdf"), fallback: false) }
  end
  .map(&:value)

native_gems = $LOADED_FEATURES.grep(%r{/(?:cairo|rsvg2|hexapdf)(?:[/.])})
raise "Prepared export loaded ordinary export gems: #{native_gems}" unless native_gems.empty?

identity = Sevgi::Sundries::Imprint.fingerprint
raise "Unexpected Mainz runtime report" unless identity.fetch("runtime").fetch("contract") == 1
outputs.each do |output|
  Sevgi::F.sh!("qpdf", "--check", output)
  report = JSON.parse(Sevgi::F.sh!("mainz", "verify", output).out)
  raise "Invalid prepared PDF" unless report.fetch("valid")
end

require "hexapdf"

outputs.each_with_index do |output, index|
  document = HexaPDF::Document.open(output)
  raise "Wrong PDF dimensions" unless document.pages.first.box.width == 15
  files = document.catalog[:Names][:EmbeddedFiles].each_entry.to_h
  manifest = JSON.parse(files.fetch("mainz.json")[:EF][:F].stream)
  expected_page = {"name" => "Sheet #{index + 1}", "tags" => ["practice"]}
  raise "Wrong page metadata" unless manifest.fetch("pages") == [expected_page]
  raise "Missing paint controls" unless manifest.fetch("parameters").keys.sort == %w[display opacity]
  profiles = manifest.fetch("profileSets").first.fetch("profiles")
  raise "Wrong profile overrides" unless profiles.last.fetch("overrides") == {"opacity" => 0.4}
end

summary = JSON.parse(Sevgi::F.sh!("mainz", "describe", metadata_output).out)
raise "Metadata-only PDF has paint controls" unless summary.fetch("parameters").empty?
raise "Missing metadata-only preview" unless summary.fetch("pages").first.fetch("preview").fetch("file") == "preview.png"

puts(JSON.generate(parallel_documents: outputs.size, native_export_gems_loaded: native_gems, runtime: identity))
