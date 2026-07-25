import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.esm.min.mjs';

mermaid.initialize({
  flowchart: { useMaxWidth: true },
  securityLevel: 'strict',
  startOnLoad: false,
  theme: 'base',
  themeVariables: {
    fontFamily: '"Inter", sans-serif'
  }
});

await mermaid.run({ querySelector: '.mermaid' });
