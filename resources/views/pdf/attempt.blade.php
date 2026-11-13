<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>IELTS Mock Result - {{ ($branding ?? null)?->name ?? 'Mynine' }}</title>
    <style>
        @page {
            margin: 25pt 30pt;
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 10px;
            color: #1e293b;
            line-height: 1.4;
            background-color: #ffffff;
            margin: 0;
            padding: 0;
        }

        /* Outer Frame & Watermark */
        .page-border {
            position: fixed;
            top: -15pt;
            left: -15pt;
            width: 565pt;
            height: 812pt;
            border: 2pt solid #1e1b4b;
            z-index: 1000;
        }

        .page-border-inner {
            position: fixed;
            top: -12pt;
            left: -12pt;
            width: 559pt;
            height: 806pt;
            border: 0.5pt solid #d97706;
            z-index: 1000;
        }

        .watermark {
            position: fixed;
            top: 35%;
            left: 5%;
            width: 90%;
            text-align: center;
            opacity: 0.03;
            transform: rotate(-30deg);
            font-size: 70px;
            font-weight: bold;
            color: #1e1b4b;
            z-index: -1000;
            letter-spacing: 6px;
        }

        .certificate-wrapper {
            padding: 10px 15px;
            position: relative;
        }

        /* Header Styling */
        .header-table {
            width: 100%;
            border-collapse: collapse;
            border-bottom: 2pt solid #1e1b4b;
            padding-bottom: 8px;
            margin-bottom: 12px;
        }

        .brand-title {
            font-size: 24px;
            font-weight: bold;
            color: #1e1b4b;
            letter-spacing: 1.5px;
            line-height: 1;
        }

        .brand-subtitle {
            font-size: 8.5px;
            color: #d97706;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-top: 3px;
        }

        .trf-header-right {
            text-align: right;
            vertical-align: middle;
        }

        .trf-badge {
            display: inline-block;
            background: #1e1b4b;
            color: #ffffff;
            font-size: 11px;
            font-weight: bold;
            padding: 4px 12px;
            border-radius: 4px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .trf-number {
            font-size: 9px;
            color: #64748b;
            font-weight: bold;
            margin-top: 4px;
        }

        /* Section Headings */
        .section-header {
            background: #1e1b4b;
            color: #ffffff;
            font-size: 9.5px;
            font-weight: bold;
            padding: 4px 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 10px;
            margin-bottom: 8px;
            border-radius: 2px;
        }

        /* Candidate Details Card */
        .candidate-card {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 4px;
        }

        .candidate-card td {
            padding: 5px 8px;
            border: 1px solid #e2e8f0;
            font-size: 9.5px;
            vertical-align: middle;
        }

        .field-label {
            font-weight: bold;
            color: #475569;
            width: 18%;
            background: #f1f5f9;
        }

        .field-value {
            color: #0f172a;
            width: 32%;
            font-weight: 500;
        }

        .field-value-strong {
            color: #1e1b4b;
            font-weight: bold;
            font-size: 10.5px;
        }

        /* Band Scores Section */
        .scores-container {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
        }

        .module-table {
            width: 100%;
            border-collapse: collapse;
            text-align: center;
        }

        .module-table th {
            background: #312e81;
            color: #ffffff;
            font-size: 9.5px;
            font-weight: bold;
            padding: 6px 4px;
            text-transform: uppercase;
            border: 1px solid #1e1b4b;
        }

        .module-table td {
            padding: 8px 4px;
            border: 1px solid #cbd5e1;
            font-size: 10px;
            background: #ffffff;
        }

        .module-raw {
            font-size: 8.5px;
            color: #64748b;
            margin-top: 2px;
        }

        .module-band {
            font-size: 14px;
            font-weight: bold;
            color: #1e1b4b;
        }

        /* Overall Band Banner */
        .overall-banner {
            width: 100%;
            background: #fffbeb;
            border: 1.5pt solid #d97706;
            border-radius: 6px;
            padding: 10px;
            text-align: center;
            margin-top: 10px;
            margin-bottom: 12px;
        }

        .overall-banner table {
            width: 100%;
            border-collapse: collapse;
        }

        .overall-title {
            font-size: 11px;
            font-weight: bold;
            color: #92400e;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .overall-score-display {
            font-size: 32px;
            font-weight: bold;
            color: #1e1b4b;
            line-height: 1;
            margin: 4px 0;
        }

        .cefr-badge {
            display: inline-block;
            background: #d97706;
            color: #ffffff;
            font-size: 9px;
            font-weight: bold;
            padding: 2px 10px;
            border-radius: 10px;
            text-transform: uppercase;
        }

        /* CEFR Reference Bar */
        .cefr-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 14px;
            font-size: 8px;
            text-align: center;
        }

        .cefr-table th {
            background: #e2e8f0;
            color: #334155;
            padding: 3px;
            font-weight: bold;
            border: 1px solid #cbd5e1;
        }

        .cefr-table td {
            padding: 3px;
            border: 1px solid #cbd5e1;
            background: #f8fafc;
            color: #475569;
        }

        .cefr-active {
            background: #fef3c7 !important;
            font-weight: bold;
            color: #92400e !important;
            border: 1.5pt solid #d97706 !important;
        }

        /* Writing & Detailed Feedback Section */
        .feedback-card {
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            margin-bottom: 12px;
            padding: 10px;
            page-break-inside: avoid;
        }

        .feedback-title {
            font-size: 11px;
            font-weight: bold;
            color: #1e1b4b;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            margin-bottom: 8px;
        }

        .criteria-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 9px;
            margin-bottom: 8px;
        }

        .criteria-table td {
            padding: 3px 6px;
            border-bottom: 1px solid #f1f5f9;
        }

        /* Verification Footer */
        .footer-box {
            width: 100%;
            border-top: 1.5pt solid #1e1b4b;
            padding-top: 8px;
            margin-top: 12px;
        }

        .footer-table {
            width: 100%;
            border-collapse: collapse;
        }

        .footer-info {
            font-size: 7.5px;
            color: #64748b;
            line-height: 1.3;
            vertical-align: middle;
        }

        .qr-cell {
            text-align: right;
            width: 80px;
            vertical-align: middle;
        }

        .qr-img {
            width: 65px;
            height: 65px;
            border: 1px solid #cbd5e1;
            padding: 2px;
            background: #ffffff;
        }

        .seal-box {
            display: inline-block;
            border: 1.5pt dashed #1e1b4b;
            padding: 4px 8px;
            text-align: center;
            border-radius: 4px;
            margin-right: 15px;
        }

        .seal-text {
            font-size: 7.5px;
            font-weight: bold;
            color: #1e1b4b;
            text-transform: uppercase;
        }
    </style>
</head>
<body>

@php
    if (!function_exists('parseMarkdownToHtml')) {
        function parseMarkdownToHtml($text) {
            if (empty($text)) return '';
            $html = htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
            $html = preg_replace('/^###\s+(.+)$/m', '<strong style="color: #1e1b4b; font-size: 9.5px; display: block; margin-top: 6px; margin-bottom: 3px;">$1</strong>', $html);
            $html = preg_replace('/^##\s+(.+)$/m', '<strong style="color: #1e1b4b; font-size: 10.5px; display: block; margin-top: 8px; margin-bottom: 4px;">$1</strong>', $html);
            $html = preg_replace('/^#\s+(.+)$/m', '<strong style="color: #1e1b4b; font-size: 11.5px; display: block; margin-top: 10px; border-bottom: 1px solid #cbd5e1; padding-bottom: 2px; margin-bottom: 6px;">$1</strong>', $html);
            $html = preg_replace('/\*\*(.*?)\*\*/', '<strong>$1</strong>', $html);
            $html = preg_replace('/^\s*[-*]\s+(.+)$/m', '<div style="margin-left: 10px; margin-bottom: 2px; padding-left: 6px; border-left: 1.5px solid #cbd5e1;">$1</div>', $html);
            $html = nl2br($html);
            return $html;
        }
    }

    // Same band rules as the result page and the reception sheet (MockResultService::attemptBands):
    // Reading by the test variant, Writing = Admin-confirmed band or (T1 + 2*T2) / 3.
    $bands = app(\App\Services\MockResultService::class)->attemptBands($attempt);

    $hasListening = $bands['listening'] !== null;
    $hasReading = $bands['reading'] !== null;
    $hasWriting = $bands['writing'] !== null;
    $hasSpeaking = $bands['speaking'] !== null;

    $listeningCorrect = $bands['listening_correct'] ?? 0;
    $readingCorrect = $bands['reading_correct'] ?? 0;

    $listeningBand = $bands['listening'] ?? 0.0;
    $readingBand = $bands['reading'] ?? 0.0;
    $writingBand = $bands['writing'] ?? 0.0;
    $speakingBand = $bands['speaking'] ?? 0.0;

    $overallBand = $bands['overall'] ?? 0.0;

    // Determine CEFR Level
    $cefrLevel = 'B1 (Intermediate)';
    if ($overallBand >= 8.5) {
        $cefrLevel = 'C2 (Mastery / Expert)';
    } elseif ($overallBand >= 7.0) {
        $cefrLevel = 'C1 (Advanced)';
    } elseif ($overallBand >= 5.5) {
        $cefrLevel = 'B2 (Upper-Intermediate)';
    } elseif ($overallBand >= 4.0) {
        $cefrLevel = 'B1 (Intermediate)';
    } else {
        $cefrLevel = 'A2 / Below (Modest)';
    }
    
    $candidateName = $attempt->name 
        ?: (optional($attempt->mockStudent)->name 
        ?: (optional($attempt->user)->name ?? 'Candidate'));
    
    $candidateContact = optional($attempt->user)->phone 
        ?: (optional($attempt->user)->email 
        ?: (optional($attempt->mockStudent)->phone ?? '---'));

    $testName = optional($attempt->test)->name ?? 'General IELTS';
    $folderName = optional(optional($attempt->test)->folder)->name ?? optional($attempt->mock)->name ?? 'Practice Module';

    $verificationUrl = route('attempt.pdf', $attempt->id);
    $verificationCode = 'MY9-' . strtoupper(substr(hash('sha256', $attempt->id . $attempt->created_at), 0, 8));

    // A center's result: its own name / logo (partners also "Powered by Mynine"); practice keeps MYNINE.UZ.
    $branding = $branding ?? null;
@endphp

<div class="page-border"></div>
<div class="page-border-inner"></div>
<div class="watermark">{{ $branding ? mb_strtoupper($branding->name) : 'MYNINE ACADEMY' }}</div>

<div class="certificate-wrapper">
    <!-- Header -->
    <table class="header-table">
        <tr>
            <td style="vertical-align: middle;">
                @if ($branding)
                    @if ($logo = $branding->logoDataUri())
                        <img src="{{ $logo }}" alt="" style="max-height: 34px; max-width: 160px; vertical-align: middle; margin-right: 6px;">
                    @endif
                    <span class="brand-title" style="vertical-align: middle;">{{ $branding->name }}</span>
                    <div class="brand-subtitle">IELTS Mock Exam{!! $branding->partner ? ' &middot; Powered by Mynine' : '' !!}</div>
                @else
                    <div class="brand-title">MYNINE.UZ</div>
                    <div class="brand-subtitle">IELTS Preparation Platform</div>
                @endif
            </td>
            <td class="trf-header-right">
                <div class="trf-badge">Test Report Form</div>
                <div class="trf-number">TRF Number: <strong>{{ $verificationCode }}</strong></div>
            </td>
        </tr>
    </table>

    <!-- Candidate Info -->
    <div class="section-header">Candidate Details</div>
    <table class="candidate-card">
        <tr>
            <td class="field-label">Candidate Name:</td>
            <td class="field-value field-value-strong">{{ strtoupper($candidateName) }}</td>
            <td class="field-label">Attempt ID:</td>
            <td class="field-value">#{{ $attempt->id }}</td>
        </tr>
        <tr>
            <td class="field-label">Test / Exam:</td>
            <td class="field-value">{{ $folderName }} - {{ $testName }}</td>
            <td class="field-label">Date of Test:</td>
            <td class="field-value">{{ $attempt->created_at->format('d M Y, H:i') }}</td>
        </tr>
        <tr>
            <td class="field-label">Candidate Contact:</td>
            <td class="field-value">{{ $candidateContact }}</td>
            <td class="field-label">Test Mode:</td>
            <td class="field-value">{{ optional($attempt->mock)->name ? 'Mock Exam' : 'Full Practice Exam' }}</td>
        </tr>
    </table>

    <!-- Module Band Scores -->
    <div class="section-header">Test Results & Component Band Scores</div>
    <table class="module-table">
        <thead>
            <tr>
                <th style="width: 25%;">Listening</th>
                <th style="width: 25%;">Reading</th>
                <th style="width: 25%;">Writing</th>
                <th style="width: 25%;">Speaking</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>
                    @if($hasListening)
                        <div class="module-band">{{ number_format($listeningBand, 1) }}</div>
                        <div class="module-raw">{{ $listeningCorrect }} / 40 Raw Score</div>
                    @else
                        <div class="module-band" style="color: #94a3b8;">N/A</div>
                        <div class="module-raw">Not attempted</div>
                    @endif
                </td>
                <td>
                    @if($hasReading)
                        <div class="module-band">{{ number_format($readingBand, 1) }}</div>
                        <div class="module-raw">{{ $readingCorrect }} / 40 Raw Score</div>
                    @else
                        <div class="module-band" style="color: #94a3b8;">N/A</div>
                        <div class="module-raw">Not attempted</div>
                    @endif
                </td>
                <td>
                    @if($hasWriting)
                        <div class="module-band">{{ number_format((float)$writingBand, 1) }}</div>
                        <div class="module-raw">AI Evaluated</div>
                    @else
                        <div class="module-band" style="color: #94a3b8;">N/A</div>
                        <div class="module-raw">Not attempted</div>
                    @endif
                </td>
                <td>
                    @if($hasSpeaking)
                        <div class="module-band">{{ number_format($speakingBand, 1) }}</div>
                        <div class="module-raw">Examiner Assessed</div>
                    @else
                        <div class="module-band" style="color: #94a3b8;">N/A</div>
                        <div class="module-raw">Not attempted</div>
                    @endif
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Overall Score Box -->
    <div class="overall-banner">
        <table>
            <tr>
                <td style="width: 50%; text-align: center; border-right: 1.5pt solid #fde68a;">
                    <div class="overall-title">Overall Band Score</div>
                    <div class="overall-score-display">{{ number_format($overallBand, 1) }}</div>
                </td>
                <td style="width: 50%; text-align: center; padding-left: 10px;">
                    <div style="font-size: 10px; font-weight: bold; color: #92400e; text-transform: uppercase; margin-bottom: 4px;">CEFR Level Equivalent</div>
                    <div class="cefr-badge">{{ $cefrLevel }}</div>
                    <div style="font-size: 8px; color: #78350f; margin-top: 4px;">Standardized IELTS Academic Scale</div>
                </td>
            </tr>
        </table>
    </div>

    <!-- CEFR Reference Scale -->
    <table class="cefr-table">
        <tr>
            <th style="width: 14%;">Band 0 - 3.5</th>
            <th style="width: 14%;">Band 4.0 - 5.0</th>
            <th style="width: 18%;">Band 5.5 - 6.5</th>
            <th style="width: 18%;">Band 7.0 - 8.0</th>
            <th style="width: 18%;">Band 8.5 - 9.0</th>
            <th style="width: 18%;">CEFR Match</th>
        </tr>
        <tr>
            <td class="{{ $overallBand <= 3.5 ? 'cefr-active' : '' }}">A1 - A2 User</td>
            <td class="{{ ($overallBand >= 4.0 && $overallBand <= 5.0) ? 'cefr-active' : '' }}">B1 Intermediate</td>
            <td class="{{ ($overallBand >= 5.5 && $overallBand <= 6.5) ? 'cefr-active' : '' }}">B2 Upper-Int.</td>
            <td class="{{ ($overallBand >= 7.0 && $overallBand <= 8.0) ? 'cefr-active' : '' }}">C1 Advanced</td>
            <td class="{{ $overallBand >= 8.5 ? 'cefr-active' : '' }}">C2 Mastery</td>
            <td style="font-weight: bold; color: #1e1b4b;">{{ explode(' ', $cefrLevel)[0] }}</td>
        </tr>
    </table>

    <!-- Writing Task Detailed AI Feedback (If Available) -->
    @php $hasFeedbackSection = false; @endphp
    @foreach($attempt->attempt_types as $type)
        @if($type->type && $type->type->name === 'Writing')
            @foreach($type->attempt_parts ?? [] as $part)
                @foreach(optional($part->part)->sections ?? [] as $sec)
                    @foreach($sec->questions as $q)
                        @if(optional($q->attempt_answer)->review_note_ai)
                            @php
                                $hasFeedbackSection = true;
                                $reviewText = $q->attempt_answer->review_note_ai;
                                
                                preg_match('/Overall Band Score:\s*([0-9.]+)/i', $reviewText, $matches);
                                $essayOverall = $matches[1] ?? null;

                                preg_match('/Task Response:\s*([0-9.]+)/i', $reviewText, $matches);
                                $taskResponse = $matches[1] ?? 'N/A';

                                preg_match('/Coherence & Cohesion:\s*([0-9.]+)/i', $reviewText, $matches);
                                $coherenceCohesion = $matches[1] ?? 'N/A';

                                preg_match('/Lexical Resource:\s*([0-9.]+)/i', $reviewText, $matches);
                                $lexicalResource = $matches[1] ?? 'N/A';

                                preg_match('/Grammatical Range & Accuracy:\s*([0-9.]+)/i', $reviewText, $matches);
                                $grammaticalRange = $matches[1] ?? 'N/A';

                                $feedbackParts = explode('Detailed Feedback:', $reviewText);
                                $detailedFeedback = count($feedbackParts) > 1 ? trim($feedbackParts[1]) : $reviewText;
                            @endphp
                            <div style="page-break-before: always;">
                                <div class="section-header">Writing Task {{ $loop->iteration }} Diagnostic Evaluation</div>
                                <div class="feedback-card">
                                    <table style="width: 100%; border-collapse: collapse; margin-bottom: 10px;">
                                        <tr>
                                            <td style="width: 60%; vertical-align: top; padding-right: 12px; border-right: 1px solid #e2e8f0;">
                                                <div style="font-weight: bold; color: #1e1b4b; margin-bottom: 4px; font-size: 10px;">Submitted Response:</div>
                                                <div style="white-space: pre-wrap; color: #334155; font-size: 9px; line-height: 1.4; max-height: 280px;">{{ $q->attempt_answer->answer_text }}</div>
                                            </td>
                                            <td style="width: 40%; vertical-align: top; padding-left: 12px;">
                                                <div style="font-weight: bold; color: #1e1b4b; margin-bottom: 6px; text-transform: uppercase; font-size: 10px;">Criterion Band Scores:</div>
                                                <table class="criteria-table">
                                                    <tr>
                                                        <td style="color: #64748b;">Task Achievement:</td>
                                                        <td style="text-align: right; font-weight: bold; color: #1e1b4b;">{{ $taskResponse }}</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="color: #64748b;">Coherence & Cohesion:</td>
                                                        <td style="text-align: right; font-weight: bold; color: #1e1b4b;">{{ $coherenceCohesion }}</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="color: #64748b;">Lexical Resource:</td>
                                                        <td style="text-align: right; font-weight: bold; color: #1e1b4b;">{{ $lexicalResource }}</td>
                                                    </tr>
                                                    <tr>
                                                        <td style="color: #64748b;">Grammatical Range:</td>
                                                        <td style="text-align: right; font-weight: bold; color: #1e1b4b;">{{ $grammaticalRange }}</td>
                                                    </tr>
                                                    @if($essayOverall)
                                                    <tr style="background: #f8fafc;">
                                                        <td style="padding: 5px 6px; color: #d97706; font-weight: bold; font-size: 10px;">Task Overall Band:</td>
                                                        <td style="padding: 5px 6px; text-align: right; font-weight: bold; color: #d97706; font-size: 11px;">{{ $essayOverall }}</td>
                                                    </tr>
                                                    @endif
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
                                    
                                    <div style="border-top: 1px solid #e2e8f0; padding-top: 8px; margin-top: 6px;">
                                        <div style="font-weight: bold; color: #1e1b4b; margin-bottom: 4px; font-size: 9.5px;">Examiner Feedback & Suggestions for Band 8.0+:</div>
                                        <div style="color: #334155; font-size: 9px; line-height: 1.45;">
                                            {!! parseMarkdownToHtml($detailedFeedback) !!}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @endif
                    @endforeach
                @endforeach
            @endforeach
        @endif
    @endforeach

    <!-- Official Seal & Security Verification Footer -->
    <div class="footer-box">
        <table class="footer-table">
            <tr>
                <td style="width: 75%;" class="footer-info">
                    <div style="margin-bottom: 4px;">
                        <span class="seal-box">
                            <span class="seal-text">✓ {{ $branding ? mb_strtoupper($branding->name).' ASSESSMENT' : 'MYNINE CERTIFIED ASSESSMENT' }}</span>
                        </span>
                        <strong>Verification Code:</strong> <code>{{ $verificationCode }}</code>
                    </div>
                    @if ($branding)
                    <strong>Disclaimer:</strong> This mock exam result is issued by {{ $branding->name }}{{ $branding->partner ? ' (powered by Mynine)' : '' }} and is not an official IELTS Test Report Form. The scores
                    @else
                    <strong>Disclaimer:</strong> This Test Report Form is issued by MyNine.uz Academic Preparation Platform. The scores
                    @endif are generated based on official Cambridge IELTS criteria and intended for performance monitoring and practice evaluation.<br>
                    <strong>Online Verification:</strong> <a href="{{ $verificationUrl }}" style="color: #312e81; text-decoration: none;">{{ $verificationUrl }}</a> | Generated: {{ now()->format('Y-m-d H:i:s') }}
                </td>
                <td class="qr-cell">
                    <img class="qr-img" src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data={{ urlencode($verificationUrl) }}" alt="Verify QR">
                </td>
            </tr>
        </table>
    </div>
</div>

</body>
</html>
