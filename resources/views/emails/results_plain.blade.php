Hello {{ $user->name }},

Your test attempt is complete.

Download the PDF: {{ url(\Illuminate\Support\Facades\URL::signedRoute('attempt.pdf', ['attempt' => $result->id], null, false)) }}
View the full results: {{ url('/attempt/'.$result->id) }}

Thanks,
{{ config('app.name') }}
