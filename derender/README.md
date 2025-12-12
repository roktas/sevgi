# API

Tepe seviye

- `Derender(file, id)`: SVG file dosyasından id'li elemanı XML düğümü (Node) olarak dön
- `Derender(file, id)` = `Derender.(file, id)`
- `node` bir XML düğümü, `element` bir Sevgi element'i ise `node.(element)` ilgili node'u element altında evaluate eder
- `Include(file, id)`: SVG file dosyasında id'li düğümü al ve ilgili kapsamda (`self`) evaluate et
- `Include(file, id) = Derender.(file, id).(self)`

Düğüm (`Node`) seviyesi

- `node.meta`: düğümde `_:*` şeklindeki tüm attributelerin hash'i
- `node.attributes`: tüm attributelerin hash'i
- `node.content`: düğüm içeriği (ör. bir `text` düğümü)
- `node.children`: çocuk düğümler
- `node.name`: düğüm adı
- `node.type`: düğüm tipi
- `node.ruby_code`: biçimlendirilmemiş ruby kodu (ERB template ile dolduruluyor)
- `node.render`: Rufo ile biçimlendirilmiş ve valide edilmiş Ruby kodu
- `node.find(arg, by = "id")`: düğüm ve çocuklarında `by` niteliği (default `id`) `arg` olan düğümü dön
- `node.call(element, include_current = true)`: düğümü Sevgi `element`'i altında (`element` dahil veya hariç) evaluate et
