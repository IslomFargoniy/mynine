<?php

namespace App\Services\Import;

use GdImage;
use Smalot\PdfParser\Document;
use Smalot\PdfParser\Element\ElementArray;
use Smalot\PdfParser\Header;
use Smalot\PdfParser\Page;
use Smalot\PdfParser\Parser;
use Smalot\PdfParser\PDFObject;
use Smalot\PdfParser\XObject\Form;
use Smalot\PdfParser\XObject\Image as PdfImage;
use Symfony\Component\Process\Process;
use Throwable;

/**
 * Pictures of a PDF page for the Writing import (Task 1 chart / table / map / diagram).
 *
 * 1. embedded(): raster images placed on the page (XObject /Image). JPEG streams (DCTDecode) are kept as
 *    they are; raw samples (smalot/pdfparser already undid FlateDecode / LZW / RunLength) are rebuilt as
 *    PNG with GD: DeviceGray / RGB / CMYK, 8 bits (and 1-bit gray), PNG predictors, soft mask on white.
 * 2. renderRegion(): a chart drawn with vectors has no image, so the page is rendered with Ghostscript
 *    (config services.mock_import.ghostscript) and the AI's bounding box is cropped out with GD.
 */
class PdfImageExtractor
{
    /** Smaller pictures are logos / icons. */
    public const MIN_SIDE = 120;

    /** Wider (or taller) than this ratio is a banner / rule, not a chart. */
    public const MAX_ASPECT = 4.0;

    public const RENDER_DPI = 150;

    /** @var array<string, Document> */
    private array $documents = [];

    /** Why the last embedded() / renderRegion() call returned null (for warnings and the dry run). */
    public ?string $lastError = null;

    public function pageCount(string $pdfPath): int
    {
        return count($this->document($pdfPath)->getPages());
    }

    /**
     * Width and height of a page in points (MediaBox), or null.
     *
     * @return array{0: float, 1: float}|null
     */
    public function pageSize(string $pdfPath, int $pageNumber): ?array
    {
        $page = $this->document($pdfPath)->getPages()[$pageNumber - 1] ?? null;
        $box = $page ? ($page->getDetails()['MediaBox'] ?? null) : null;
        if (! is_array($box) || count($box) !== 4) {
            return null;
        }
        [$x0, $y0, $x1, $y1] = array_map('floatval', array_values($box));
        $size = [abs($x1 - $x0), abs($y1 - $y0)];
        $rotate = (int) ($page->getDetails()['Rotate'] ?? 0);

        return min($size) > 0 ? ($rotate % 180 !== 0 ? [$size[1], $size[0]] : $size) : null;
    }

    /**
     * Plain text of every page (1-based keys).
     *
     * @return array<int, string>
     */
    public function pageTexts(string $pdfPath): array
    {
        $texts = [];
        foreach ($this->document($pdfPath)->getPages() as $i => $page) {
            try {
                $texts[$i + 1] = $page->getText();
            } catch (Throwable) {
                $texts[$i + 1] = '';
            }
        }

        return $texts;
    }

    /**
     * Largest usable raster image of a page. With $aspect (width / height of the visual the AI saw), only
     * images of a similar shape count, so a wide header logo is not taken for a chart.
     *
     * @return array{data: string, extension: string, width: int, height: int, source: string}|null
     */
    public function embedded(string $pdfPath, int $pageNumber, ?float $aspect = null): ?array
    {
        $this->lastError = null;
        $pages = $this->document($pdfPath)->getPages();
        $page = $pages[$pageNumber - 1] ?? null;
        if (! $page) {
            $this->lastError = "the PDF has no page {$pageNumber}";

            return null;
        }

        $candidates = [];
        foreach ($this->pageImages($page) as $object) {
            $width = (int) $this->value($object, 'Width');
            $height = (int) $this->value($object, 'Height');
            if (min($width, $height) < self::MIN_SIDE || max($width, $height) / max(1, min($width, $height)) > self::MAX_ASPECT) {
                continue;
            }
            if ($aspect !== null && $aspect > 0) {
                $ratio = ($width / $height) / $aspect;
                if ($ratio > 1.6 || $ratio < 1 / 1.6) {
                    continue;
                }
            }
            $candidates[] = [$object, $width, $height];
        }

        usort($candidates, fn ($a, $b) => $b[1] * $b[2] <=> $a[1] * $a[2]);

        foreach ($candidates as [$object, $width, $height]) {
            try {
                if ($image = $this->decode($object, $width, $height)) {
                    return $image;
                }
            } catch (Throwable $e) {
                $this->lastError = 'image could not be decoded: '.$e->getMessage();
            }
        }

        $this->lastError ??= $candidates === [] ? "no embedded picture on page {$pageNumber}" : 'the embedded picture uses an unsupported format';

        return null;
    }

    /**
     * Images the page draws: XObjects from its own or inherited /Resources (dompdf and many generators
     * keep them on the /Pages node, shared by every page) that its content stream paints with "/Name Do",
     * including images inside Form XObjects.
     *
     * @return array<int, PdfImage>
     */
    private function pageImages(Page $page): array
    {
        $images = [];
        $this->collectImages($this->resourceXObjects($page, true), $this->streamText($page->get('Contents')), $images, 0);

        return array_values($images);
    }

    /**
     * @param  array<string, mixed>  $xobjects  resource name => object
     * @param  array<int, PdfImage>  $images  found images keyed by object id
     */
    private function collectImages(array $xobjects, ?string $content, array &$images, int $depth): void
    {
        $names = array_keys($xobjects);
        if ($content !== null && $content !== '') {
            preg_match_all('#/([^\s/\[\]<>(){}%]+)\s+Do\b#', $content, $m);
            $names = array_values(array_unique($m[1]));
        }

        foreach ($names as $name) {
            $object = $xobjects[$name] ?? null;
            if ($object instanceof PdfImage) {
                $images[spl_object_id($object)] = $object;
            } elseif ($object instanceof Form && $depth < 2) {
                $this->collectImages($this->resourceXObjects($object, false), (string) $object->getContent(), $images, $depth + 1);
            }
        }
    }

    /**
     * XObject resources of a page (walking up the /Parent chain for inherited resources) or of a form.
     *
     * @return array<string, mixed>
     */
    private function resourceXObjects(PDFObject $node, bool $inherit): array
    {
        $found = [];
        for ($depth = 0; $node instanceof PDFObject && $depth < 20; $depth++) {
            $resources = $node->get('Resources');
            $xobject = $resources instanceof Header || $resources instanceof PDFObject ? $resources->get('XObject') : null;
            if ($xobject instanceof Header || $xobject instanceof PDFObject) {
                $elements = $xobject instanceof Header ? $xobject->getElements() : ($xobject->getHeader()?->getElements() ?? []);
                $found += $elements;
            }
            if (! $inherit) {
                break;
            }
            $node = $node->get('Parent');
        }

        return $found;
    }

    /**
     * Decoded text of a content stream (or array of streams); null when it cannot be read.
     */
    private function streamText(mixed $contents): ?string
    {
        try {
            if ($contents instanceof PDFObject) {
                return (string) $contents->getContent();
            }
            if ($contents instanceof ElementArray) {
                $text = '';
                foreach ((array) $contents->getContent() as $stream) {
                    if ($stream instanceof PDFObject) {
                        $text .= $stream->getContent()."\n";
                    }
                }

                return $text;
            }
        } catch (Throwable) {
        }

        return null;
    }

    /**
     * Render one page with Ghostscript and crop a region given in 0-1000 page coordinates
     * ([ymin, xmin, ymax, xmax], as Gemini returns boxes). PNG bytes, or null (see $lastError).
     *
     * @param  array<int, int|float>  $box
     * @return array{data: string, extension: string, width: int, height: int, source: string}|null
     */
    public function renderRegion(string $pdfPath, int $pageNumber, array $box): ?array
    {
        $this->lastError = null;
        [$ymin, $xmin, $ymax, $xmax] = array_map('floatval', array_pad(array_values($box), 4, 0));
        if ($ymax - $ymin < 20 || $xmax - $xmin < 20) {
            $this->lastError = 'no position of the picture on the page';

            return null;
        }

        $out = tempnam(sys_get_temp_dir(), 'mock-page-');
        try {
            $process = new Process([
                (string) config('services.mock_import.ghostscript', 'gs'),
                '-q', '-dSAFER', '-dBATCH', '-dNOPAUSE', '-sDEVICE=png16m',
                '-r'.self::RENDER_DPI, '-dTextAlphaBits=4', '-dGraphicsAlphaBits=4',
                '-dFirstPage='.$pageNumber, '-dLastPage='.$pageNumber,
                '-sOutputFile='.$out, $pdfPath,
            ]);
            $process->setTimeout(120);
            $process->run();

            $page = $process->isSuccessful() && filesize($out) > 0 ? @imagecreatefrompng($out) : false;
            if (! $page) {
                $error = trim($process->getErrorOutput()) ?: trim($process->getOutput());
                $this->lastError = 'the page could not be rendered with Ghostscript'.($error !== '' ? ': '.mb_substr($error, 0, 200) : ' (is it installed?)');

                return null;
            }
        } catch (Throwable $e) {
            $this->lastError = 'Ghostscript is not available: '.mb_substr($e->getMessage(), 0, 200);

            return null;
        } finally {
            @unlink($out);
        }

        $pw = imagesx($page);
        $ph = imagesy($page);
        $pad = 15; // 1.5 % of the page on each side: the AI's box is often tight
        $x = (int) max(0, floor(($xmin - $pad) / 1000 * $pw));
        $y = (int) max(0, floor(($ymin - $pad) / 1000 * $ph));
        $w = (int) min($pw - $x, ceil(($xmax - $xmin + 2 * $pad) / 1000 * $pw));
        $h = (int) min($ph - $y, ceil(($ymax - $ymin + 2 * $pad) / 1000 * $ph));

        $crop = imagecrop($page, ['x' => $x, 'y' => $y, 'width' => $w, 'height' => $h]);
        if (! $crop) {
            $this->lastError = 'the page region could not be cropped';

            return null;
        }

        return $this->png($crop, 'rendered');
    }

    /**
     * @return array{data: string, extension: string, width: int, height: int, source: string}|null
     */
    private function decode(PdfImage $object, int $width, int $height): ?array
    {
        $data = (string) $object->getContent();

        // JPEG (DCTDecode is left encoded by the parser): keep the original bytes when GD can read them
        // (a CMYK JPEG cannot be shown by every browser either, so it is converted).
        if (str_starts_with($data, "\xFF\xD8")) {
            $gd = @imagecreatefromstring($data);
            if (! $gd) {
                $this->lastError = 'the embedded JPEG could not be read';

                return null;
            }
            $info = @getimagesizefromstring($data);
            if (($info['channels'] ?? 3) === 4) {
                return $this->png($gd, 'embedded');
            }

            return ['data' => $data, 'extension' => 'jpg', 'width' => imagesx($gd), 'height' => imagesy($gd), 'source' => 'embedded'];
        }

        foreach ($this->filters($object) as $filter) {
            if (in_array($filter, ['JPXDecode', 'JBIG2Decode', 'CCITTFaxDecode', 'DCTDecode'], true)) {
                $this->lastError = "embedded picture format {$filter} is not supported";

                return null;
            }
        }

        $colorSpace = $this->colorSpace($object);
        if ($colorSpace === null) {
            $this->lastError = 'embedded picture colour space is not supported';

            return null;
        }
        $components = ['DeviceGray' => 1, 'DeviceRGB' => 3, 'DeviceCMYK' => 4][$colorSpace];
        $bits = (int) ($this->value($object, 'BitsPerComponent') ?: 8);
        if (! in_array($bits, [1, 8], true) || ($bits === 1 && $components !== 1)) {
            $this->lastError = "embedded picture with {$bits}-bit samples is not supported";

            return null;
        }

        $rowBytes = $bits === 8 ? $width * $components : intdiv($width + 7, 8);
        $data = $this->unpredict($data, $rowBytes, $height, $bits === 8 ? $components : 1);
        if ($data === null) {
            $this->lastError = 'embedded picture data has an unexpected size';

            return null;
        }

        $alpha = $this->softMask($object, $width, $height);

        $gd = imagecreatetruecolor($width, $height);
        for ($y = 0; $y < $height; $y++) {
            $row = $y * $rowBytes;
            for ($x = 0; $x < $width; $x++) {
                if ($bits === 1) {
                    $v = (ord($data[$row + ($x >> 3)]) >> (7 - ($x & 7))) & 1 ? 255 : 0;
                    [$r, $g, $b] = [$v, $v, $v];
                } elseif ($components === 1) {
                    $r = $g = $b = ord($data[$row + $x]);
                } elseif ($components === 3) {
                    $i = $row + $x * 3;
                    [$r, $g, $b] = [ord($data[$i]), ord($data[$i + 1]), ord($data[$i + 2])];
                } else {
                    $i = $row + $x * 4;
                    $k = ord($data[$i + 3]);
                    $r = 255 - min(255, ord($data[$i]) + $k);
                    $g = 255 - min(255, ord($data[$i + 1]) + $k);
                    $b = 255 - min(255, ord($data[$i + 2]) + $k);
                }
                if ($alpha !== null) {
                    // Transparent areas are usually black in the colour samples: flatten onto white.
                    $a = ord($alpha[$y * $width + $x]) / 255;
                    $r = (int) round($r * $a + 255 * (1 - $a));
                    $g = (int) round($g * $a + 255 * (1 - $a));
                    $b = (int) round($b * $a + 255 * (1 - $a));
                }
                imagesetpixel($gd, $x, $y, ($r << 16) | ($g << 8) | $b);
            }
        }

        return $this->png($gd, 'embedded');
    }

    /**
     * Undo PNG predictors (DecodeParms /Predictor >= 10: one filter byte per row) when present.
     */
    private function unpredict(string $data, int $rowBytes, int $height, int $bpp): ?string
    {
        $plain = $rowBytes * $height;
        if (strlen($data) === $plain) {
            return $data;
        }
        if (strlen($data) < $plain) {
            return null;
        }
        if (strlen($data) !== ($rowBytes + 1) * $height) {
            // Trailing padding after the samples.
            return substr($data, 0, $plain);
        }

        $out = '';
        $prior = str_repeat("\0", $rowBytes);
        for ($y = 0; $y < $height; $y++) {
            $type = ord($data[$y * ($rowBytes + 1)]);
            $line = substr($data, $y * ($rowBytes + 1) + 1, $rowBytes);
            $cur = '';
            for ($i = 0; $i < $rowBytes; $i++) {
                $raw = ord($line[$i]);
                $left = $i >= $bpp ? ord($cur[$i - $bpp]) : 0;
                $up = ord($prior[$i]);
                $upLeft = $i >= $bpp ? ord($prior[$i - $bpp]) : 0;
                $value = match ($type) {
                    1 => $raw + $left,
                    2 => $raw + $up,
                    3 => $raw + intdiv($left + $up, 2),
                    4 => $raw + $this->paeth($left, $up, $upLeft),
                    default => $raw,
                };
                $cur .= chr($value & 0xFF);
            }
            $out .= $cur;
            $prior = $cur;
        }

        return $out;
    }

    private function paeth(int $a, int $b, int $c): int
    {
        $p = $a + $b - $c;
        $pa = abs($p - $a);
        $pb = abs($p - $b);
        $pc = abs($p - $c);

        return $pa <= $pb && $pa <= $pc ? $a : ($pb <= $pc ? $b : $c);
    }

    /**
     * 8-bit gray soft mask (/SMask) samples of the same size as the image, or null.
     */
    private function softMask(PdfImage $object, int $width, int $height): ?string
    {
        try {
            $mask = $object->getHeader()?->get('SMask');
            if (! $mask instanceof PDFObject) {
                return null;
            }
            $data = (string) $mask->getContent();

            return strlen($data) >= $width * $height ? $data : null;
        } catch (Throwable) {
            return null;
        }
    }

    /**
     * DeviceGray / DeviceRGB / DeviceCMYK (ICCBased resolved by its component count), else null.
     */
    private function colorSpace(PdfImage $object): ?string
    {
        $space = $object->getHeader()?->get('ColorSpace');
        $name = $space ? trim((string) $space) : '';
        if (in_array($name, ['DeviceGray', 'DeviceRGB', 'DeviceCMYK'], true)) {
            return $name;
        }

        // [/ICCBased <stream>]: the profile stream says how many components (N).
        $elements = $space && is_array($space->getContent()) ? $space->getContent() : [];
        if (($elements[0] ?? null) && trim((string) $elements[0]) === 'ICCBased' && ($elements[1] ?? null) instanceof PDFObject) {
            $n = (int) (string) $elements[1]->getHeader()?->get('N');

            return [1 => 'DeviceGray', 3 => 'DeviceRGB', 4 => 'DeviceCMYK'][$n] ?? null;
        }

        return null;
    }

    /**
     * @return array<int, string>
     */
    private function filters(PdfImage $object): array
    {
        $filter = $object->getHeader()?->get('Filter');
        if (! $filter) {
            return [];
        }
        $content = $filter->getContent();

        return is_array($content) ? array_map(fn ($f) => trim((string) $f), $content) : [trim((string) $filter)];
    }

    private function value(PdfImage $object, string $key): string
    {
        return trim((string) $object->getHeader()?->get($key));
    }

    /**
     * @return array{data: string, extension: string, width: int, height: int, source: string}
     */
    private function png(GdImage $gd, string $source): array
    {
        ob_start();
        imagepng($gd, null, 6);
        $data = (string) ob_get_clean();

        return ['data' => $data, 'extension' => 'png', 'width' => imagesx($gd), 'height' => imagesy($gd), 'source' => $source];
    }

    private function document(string $pdfPath): Document
    {
        return $this->documents[$pdfPath] ??= (new Parser)->parseFile($pdfPath);
    }
}
