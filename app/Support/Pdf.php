<?php

namespace App\Support;

use Dompdf\Dompdf;
use Illuminate\Http\Response;

/**
 * Small dompdf wrapper for printable A4 sheets (code cards, result sheets).
 */
class Pdf
{
    /**
     * @param  array<string, mixed>  $data
     */
    public static function render(string $view, array $data, string $filename): Response
    {
        return response(self::output($view, $data), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'inline; filename="'.preg_replace('/[^A-Za-z0-9_.-]/', '_', $filename).'.pdf"',
        ]);
    }

    /**
     * The PDF bytes of a view.
     *
     * @param  array<string, mixed>  $data
     */
    public static function output(string $view, array $data): string
    {
        $dompdf = new Dompdf([
            'isPhpEnabled' => false,
            'isRemoteEnabled' => false,
            'isHtml5ParserEnabled' => true,
            'isFontSubsettingEnabled' => true,
            'defaultFont' => 'DejaVu Sans',
        ]);
        $dompdf->loadHtml(view($view, $data)->render());
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        return (string) $dompdf->output();
    }
}
