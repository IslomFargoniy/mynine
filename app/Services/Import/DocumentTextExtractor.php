<?php

namespace App\Services\Import;

use RuntimeException;
use Smalot\PdfParser\Parser;
use Throwable;
use ZipArchive;

/**
 * Plain text from uploaded test documents (.pdf, .docx, .txt) for the AI importer.
 * Page breaks are kept as "--- Page N ---" lines so the model can see the paper layout.
 */
class DocumentTextExtractor
{
    public const EXTENSIONS = ['pdf', 'docx', 'txt'];

    /** Typographic ligatures some PDF fonts emit instead of letter pairs. */
    private const LIGATURES = ['ﬀ' => 'ff', 'ﬁ' => 'fi', 'ﬂ' => 'fl', 'ﬃ' => 'ffi', 'ﬄ' => 'ffl', 'ﬅ' => 'st', 'ﬆ' => 'st'];

    public function extract(string $path, ?string $extension = null): string
    {
        $extension = strtolower($extension ?? pathinfo($path, PATHINFO_EXTENSION));

        $text = match ($extension) {
            'pdf' => $this->fromPdf($path),
            'docx' => $this->fromDocx($path),
            'txt' => (string) file_get_contents($path),
            default => throw new RuntimeException("Unsupported file type: .{$extension}"),
        };

        return $this->clean($text);
    }

    /**
     * @param  array<int, string>  $pages
     */
    public function joinPages(array $pages): string
    {
        $out = [];
        foreach (array_values($pages) as $i => $page) {
            $out[] = '--- Page '.($i + 1).' ---';
            $out[] = trim($page);
        }

        return implode("\n", $out);
    }

    private function fromPdf(string $path): string
    {
        try {
            $pdf = (new Parser)->parseFile($path);
        } catch (Throwable $e) {
            throw new RuntimeException('The PDF could not be read: '.$e->getMessage(), 0, $e);
        }

        $pages = array_map(fn ($page) => $page->getText(), $pdf->getPages());
        $text = $this->joinPages($pages);

        if (mb_strlen(preg_replace('/--- Page \d+ ---|\s+/u', '', $text)) < 20) {
            throw new RuntimeException('The PDF has no text layer (scanned image?). Upload a text PDF or a .docx file.');
        }

        return $text;
    }

    private function fromDocx(string $path): string
    {
        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            throw new RuntimeException('The .docx file could not be opened.');
        }

        $xml = (string) $zip->getFromName('word/document.xml');
        $zip->close();

        if ($xml === '') {
            throw new RuntimeException('The .docx file has no document body.');
        }

        $pages = preg_split('#<w:br\b[^>]*w:type="page"[^>]*/>|<w:lastRenderedPageBreak/>#', $xml) ?: [$xml];

        $pages = array_map(function (string $xml) {
            $xml = preg_replace('#<w:tab/>#', "\t", $xml);
            $xml = preg_replace('#<w:br\b[^>]*/>#', "\n", $xml);
            $xml = preg_replace('#</w:p>#', "\n", $xml);

            return html_entity_decode(strip_tags($xml), ENT_QUOTES | ENT_XML1, 'UTF-8');
        }, $pages);

        return count($pages) > 1 ? $this->joinPages($pages) : $pages[0];
    }

    private function clean(string $text): string
    {
        $text = strtr($text, self::LIGATURES);
        $text = str_replace(["\r\n", "\r", "\u{00A0}", "\t"], ["\n", "\n", ' ', ' '], $text);
        $text = preg_replace('/[ ]{2,}/u', ' ', $text);
        $text = preg_replace('/[ ]+\n/u', "\n", $text);
        $text = preg_replace("/\n{3,}/u", "\n\n", $text);

        return trim($text);
    }
}
