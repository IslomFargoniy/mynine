<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Attempt Completed</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f7;
            color: #333333;
            margin: 0;
            padding: 0;
        }
        .email-container {
            max-width: 600px;
            margin: 30px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .email-header {
            background-color: #4CAF50;
            color: #ffffff;
            text-align: center;
            padding: 20px;
        }
        .email-body {
            padding: 30px 20px;
            line-height: 1.6;
        }
        .email-body h1 {
            color: #4CAF50;
            font-size: 22px;
        }
        .email-body p {
            margin-bottom: 15px;
        }
        .btn {
            display: inline-block;
            padding: 12px 20px;
            margin: 10px 0;
            text-decoration: none;
            color: #ffffff;
            background-color: #4CAF50;
            border-radius: 5px;
            font-weight: bold;
        }
        .btn-secondary {
            background-color: #2196F3;
        }
        .footer {
            background-color: #f4f4f7;
            text-align: center;
            padding: 15px;
            font-size: 12px;
            color: #888888;
        }
    </style>
</head>
<body>
<div class="email-container">
    <div class="email-header">
        <h2>{{ config('app.name') }}</h2>
    </div>
    <div class="email-body">
        <h1>Hello {{ $user->name }},</h1>
        <p>Your test attempt is complete! 🎉</p>

        <p>
            <a href="{{ url(\Illuminate\Support\Facades\URL::signedRoute('attempt.pdf', ['attempt' => $result->id], null, false)) }}" class="btn">Download PDF</a>
        </p>
        <p>
            <a href="{{ url('/attempt/'.$result->id) }}" class="btn btn-secondary">View Full Results</a>
        </p>

        <div style="margin-top: 20px; padding: 15px; background-color: #f9f9f9; border-left: 4px solid #4CAF50;">
            <p><strong>💳 Bizni Qo'llab-quvvatlang:</strong></p>
            <p style="font-size: 18px; letter-spacing: 1px;">9860600402432220</p>
            <p>Donat qilishingiz mumkin.</p>
        </div>

        <p>Thanks,<br>{{ config('app.name') }}</p>
    </div>
</div>
<div class="footer">
    &copy; {{ date('Y') }} {{ config('app.name') }}. All rights reserved.
</div>
</body>
</html>
