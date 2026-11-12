<?php

namespace App\Services;

use App\Models\Attempt;
use App\Support\CenterBranding;
use Dompdf\Dompdf;
use Illuminate\Support\Facades\File;

/**
 * Result sheet PDF of an attempt (web download, Telegram). Dompdf writes its font cache and temp files
 * under storage/ (writable by the app user) instead of vendor/, which is owned by the deploy user on
 * production and made the result jobs fail.
 */
class AttemptPdfRenderer
{
    public function render(Attempt $attempt): string
    {
        $attempt->load(['test.folder', 'user', 'mock', 'mockStudent', 'attempt_types.type']);
        $attempt->attempt_types->each(fn ($attemptType) => $attemptType->append('attempt_parts'));

        $fontDir = storage_path('fonts');
        $tempDir = storage_path('app/dompdf');
        File::ensureDirectoryExists($fontDir);
        File::ensureDirectoryExists($tempDir);

        $dompdf = new Dompdf([
            'isPhpEnabled' => false,
            'isRemoteEnabled' => true,
            'isHtml5ParserEnabled' => true,
            'isFontSubsettingEnabled' => true,
            'isUnicodeEnabled' => true,
            'defaultFont' => 'DejaVu Sans',
            'fontDir' => $fontDir,
            'fontCache' => $fontDir,
            'tempDir' => $tempDir,
        ]);
        $branding = CenterBranding::forCenter($attempt->centerId());
        $dompdf->loadHtml(view('pdf.attempt', compact('attempt', 'branding'))->render());
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        $dompdf->getCanvas()->page_text(520, 815, '{PAGE_NUM} / {PAGE_COUNT}', null, 9, [0.4, 0.4, 0.4]);

        return $dompdf->output();
    }
}
