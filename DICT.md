# Dictionary

This dictionary defines Sevgi's PDF authoring terms.

## Terms

**Document RDF**
Metadata authored inside the SVG root's `metadata` element, including title, description, creator, and rights.
PDF export transfers the supported Dublin Core and Creative Commons properties to XMP.

**PDF XMP**
Document metadata stored as RDF in the PDF metadata stream. It describes the publication as a whole.
For assembled publications, `Export.metadata` supplies the final title, description, creator, and rights.

**Imprint**
In Graphics, the operation attaches an immutable SVG declaration for PDF page metadata and editable paint controls.
In Sundries, it produces a PDF from SVG and that declaration through the native Mainz CLI.

**SVG declaration**
Separate JSON-compatible data that describes source targets, editable parameters, and optional page metadata, groups, and profiles.
Mainz resolves the declaration against the SVG to produce a PDF.
