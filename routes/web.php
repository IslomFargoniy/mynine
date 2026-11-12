<?php

use App\Http\Controllers\AllTestController;
use App\Http\Controllers\AttemptAnswerController;
use App\Http\Controllers\AttemptController;
use App\Http\Controllers\AttemptPartController;
use App\Http\Controllers\AttemptTypeController;
use App\Http\Controllers\Auth\GithubAuthController;
use App\Http\Controllers\Auth\GoogleAuthController;
use App\Http\Controllers\Auth\TelegramAuthController;
use App\Http\Controllers\Auth\TelegramLoginController;
use App\Http\Controllers\BlogController;
use App\Http\Controllers\Center\CenterController;
use App\Http\Controllers\Center\CenterSettingsController;
use App\Http\Controllers\Center\ReportController;
use App\Http\Controllers\Center\StaffController;
use App\Http\Controllers\Desktop\DeviceController as DesktopDeviceController;
use App\Http\Controllers\Desktop\SettingsController as DesktopSettingsController;
use App\Http\Controllers\FolderController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\LandingPageController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\MockBankController;
use App\Http\Controllers\MockController;
use App\Http\Controllers\MockStudentController;
use App\Http\Controllers\MonitorController;
use App\Http\Controllers\OptionController;
use App\Http\Controllers\PartController;
use App\Http\Controllers\PracticeController;
use App\Http\Controllers\QuestionController;
use App\Http\Controllers\QuestionTypeController;
use App\Http\Controllers\ReceptionController;
use App\Http\Controllers\SectionController;
use App\Http\Controllers\SeoPageController;
use App\Http\Controllers\SitemapController;
use App\Http\Controllers\SpeakingController;
use App\Http\Controllers\Telegram\MynineUzBotController;
use App\Http\Controllers\Telegram\TelegramController;
use App\Http\Controllers\TestController;
use App\Http\Controllers\TestImportController;
use App\Http\Controllers\TestTypeController;
use App\Http\Controllers\User\UserController;
use App\Http\Controllers\WritingReviewController;
use App\Http\Middleware\EnsureCandidateOrAuthenticated;
use App\Http\Middleware\SetLocale;
use App\Http\Middleware\VerifyTelegramWebhook;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public
|--------------------------------------------------------------------------
*/

Route::get('/', [HomeController::class, 'home'])->name('home');
Route::get('/sitemap.xml', [SitemapController::class, 'index'])->name('sitemap');

// SEO content (server-rendered Blade)
Route::get('/blog', [BlogController::class, 'index'])->name('blog.index');
Route::get('/blog/{slug}', [BlogController::class, 'show'])->where('slug', '[a-z0-9-]+')->name('blog.show');
Route::get('/{page}', [SeoPageController::class, 'show'])
    ->whereIn('page', array_keys(SeoPageController::PAGES))
    ->name('seo.page');
Route::get('landing-page-tests', [LandingPageController::class, 'tests'])->name('landing-page-tests');

Route::post('/webapp-login', [TelegramAuthController::class, 'login']);
Route::post('/bot/webhook', [TelegramController::class, 'handle'])->middleware(VerifyTelegramWebhook::class);
Route::post('/bot/MynineUzBot/webhook', [MynineUzBotController::class, 'handle'])->middleware(VerifyTelegramWebhook::class);

// Candidate code entry (brute-force protected)
Route::match(['get', 'post'], '/mock-student/enter', [MockStudentController::class, 'enter'])
    ->middleware('throttle:10,1')
    ->name('mock-student.enter');

// PDF is reachable with a signed URL (email / Telegram) or by anyone allowed to view the attempt.
Route::get('attempt-pdf/{attempt}', [AttemptController::class, 'pdf'])->name('attempt.pdf');

// Language switcher: remembers the choice for server-rendered text (see SetLocale). The SPA calls it with
// fetch (Accept: application/json → 204); a plain link goes back to the previous page.
Route::get('/lang/{locale}', function (Request $request, string $locale) {
    abort_unless(in_array($locale, SetLocale::SUPPORTED, true), 400);
    session(['locale' => $locale]);
    app()->setLocale($locale);

    return $request->expectsJson() ? response()->noContent() : back();
})->name('lang.switch');

/*
|--------------------------------------------------------------------------
| Authenticated users (students, reception, admins)
|--------------------------------------------------------------------------
*/

// center.active: staff of a suspended center may only read (GET) — see EnsureCenterIsActive.
Route::middleware(['auth', 'verified', 'center.active'])->group(function () {
    Route::get('dashboard', [HomeController::class, 'index'])->name('dashboard');

    // Test Bank (practice tests by folder). Old URLs redirect here.
    Route::get('test-bank', [AllTestController::class, 'index'])->name('test-bank.index');
    Route::get('all-test', fn (Request $request) => redirect()->route('test-bank.index', $request->query()))->name('all-test.index');
    Route::get('folder', fn (Request $request) => redirect()->route('test-bank.index', $request->query()))->name('folder.index');
    Route::get('folder/{folder}', fn (int $folder) => redirect()->route('test-bank.index', ['folder_id' => $folder]))
        ->whereNumber('folder')
        ->name('folder.show');
    Route::resource('attempt', AttemptController::class)->only(['index', 'store', 'show', 'destroy']);

    /*
    | Centers (SuperAdmin): create / edit / suspend centers, replace a center's Admin, switch the active center.
    */
    Route::middleware('role:SuperAdmin')->prefix('centers')->name('centers.')->group(function () {
        Route::get('/', [CenterController::class, 'index'])->name('index');
        Route::post('/', [CenterController::class, 'store'])->name('store');
        Route::patch('{center}', [CenterController::class, 'update'])->whereNumber('center')->name('update');
        Route::post('{center}/status', [CenterController::class, 'status'])->whereNumber('center')->name('status');
        Route::post('{center}/replace-admin', [CenterController::class, 'replaceAdmin'])->whereNumber('center')->name('replace-admin');
        Route::post('{center}/switch', [CenterController::class, 'switch'])->whereNumber('center')->name('switch');
    });

    /*
    | Reports (SuperAdmin): billed candidates, mocks and AI cost per center and month. Usage: a center Admin's own row.
    */
    Route::get('/reports', [ReportController::class, 'index'])->middleware('role:SuperAdmin')->name('reports.index');
    Route::middleware('role:Admin|SuperAdmin')->group(function () {
        Route::get('/reports/candidates', [ReportController::class, 'candidates'])->name('reports.candidates');
        Route::get('/usage', [ReportController::class, 'usage'])->name('usage.index');
    });

    /*
    | Content management and grading: the center's Admin (every list and record is limited to the
    | current center: App\Support\CurrentCenter + policies). Suspended centers are read-only.
    */
    Route::middleware('role:Admin|SuperAdmin')->group(function () {
        // Center settings (name, logo; the center password and background are under desktop/settings).
        Route::get('/center/settings', [CenterSettingsController::class, 'edit'])->name('center.settings');
        Route::post('/center/settings', [CenterSettingsController::class, 'update'])->name('center.settings.update');
        Route::delete('/center/logo', [CenterSettingsController::class, 'destroyLogo'])->name('center.logo.destroy');

        // Reception staff of the center
        Route::get('/staff', [StaffController::class, 'index'])->name('staff.index');
        Route::post('/staff', [StaffController::class, 'store'])->name('staff.store');
        Route::patch('/staff/{staff}', [StaffController::class, 'update'])->whereNumber('staff')->name('staff.update');
        Route::post('/staff/{staff}/suspend', [StaffController::class, 'suspend'])->whereNumber('staff')->name('staff.suspend');
        Route::post('/staff/{staff}/activate', [StaffController::class, 'activate'])->whereNumber('staff')->name('staff.activate');

        Route::resource('user', UserController::class);
        Route::resource('folder', FolderController::class)->only(['store', 'update', 'destroy']);

        Route::resource('test', TestController::class)->except(['update']);
        Route::post('/test/{test}/update', [TestController::class, 'update'])->name('test.update');
        Route::resource('test-type', TestTypeController::class)->only(['show']);

        Route::resource('part', PartController::class)->except(['update']);
        Route::post('/part/{part}/update', [PartController::class, 'update'])->name('part.update');
        Route::post('/part/{part}/import-ai', [TestImportController::class, 'importAI'])->name('part.import-ai');

        Route::resource('section', SectionController::class)->only(['store', 'update', 'destroy']);
        Route::post('/section/{section}/options/sync', [SectionController::class, 'syncOptions'])->name('section.options.sync');
        Route::resource('question', QuestionController::class)->only(['store', 'update', 'destroy']);
        Route::resource('question-type', QuestionTypeController::class)->only(['index']);
        Route::resource('option', OptionController::class)->only(['store', 'update', 'destroy']);

        Route::resource('mock', MockController::class)->only(['index', 'create', 'store', 'show', 'edit', 'update', 'destroy']);
        Route::delete('/mock-student/{mockStudent}', [MockStudentController::class, 'destroy'])->name('mock-student.destroy');

        // Mock Bank (tests with purpose=mock, per module)
        Route::get('/mock-bank', [MockBankController::class, 'index'])->name('mock-bank.index');
        Route::post('/mock-bank/{test}/status', [MockBankController::class, 'updateStatus'])->name('mock-bank.status');
        Route::post('/mock-bank/{test}/to-practice', [MockBankController::class, 'toPractice'])->name('mock-bank.to-practice');
        Route::post('/mock-bank/{test}/import', [MockBankController::class, 'import'])->name('mock-bank.import');

        // Speaking slots and examiner bands
        Route::get('/speaking', [SpeakingController::class, 'index'])->name('speaking.index');
        Route::post('/speaking/mock/{mock}/auto-assign', [SpeakingController::class, 'autoAssign'])->name('speaking.auto-assign');
        Route::post('/speaking/candidates/{mockStudent}/slot', [SpeakingController::class, 'updateSlot'])->name('speaking.slot');
        Route::post('/speaking/candidates/{mockStudent}/score', [SpeakingController::class, 'score'])->name('speaking.score');

        // Writing review queue
        Route::get('/writing-review', [WritingReviewController::class, 'index'])->name('writing-review.index');
        Route::post('/writing-review/{attemptType}/confirm', [WritingReviewController::class, 'confirm'])->name('writing-review.confirm');

        // Desktop exam app: PCs, settings (installers: static public/desktop/)
        Route::prefix('desktop')->name('desktop.')->group(function () {
            Route::get('devices', [DesktopDeviceController::class, 'index'])->name('devices.index');
            Route::post('devices/{device}/approve', [DesktopDeviceController::class, 'approve'])->name('devices.approve');
            Route::post('devices/{device}/block', [DesktopDeviceController::class, 'block'])->name('devices.block');
            Route::post('devices/{device}/unblock', [DesktopDeviceController::class, 'unblock'])->name('devices.unblock');
            Route::patch('devices/{device}', [DesktopDeviceController::class, 'update'])->name('devices.update');
            Route::delete('devices/{device}', [DesktopDeviceController::class, 'destroy'])->name('devices.destroy');

            Route::get('settings', [DesktopSettingsController::class, 'index'])->name('settings.index');
            Route::post('settings/exit-password', [DesktopSettingsController::class, 'updateExitPassword'])->name('settings.exit-password');
            Route::get('settings/background', [DesktopSettingsController::class, 'showBackground'])->name('settings.background');
            Route::post('settings/background', [DesktopSettingsController::class, 'updateBackground'])->name('settings.background.update');
            Route::delete('settings/background', [DesktopSettingsController::class, 'destroyBackground'])->name('settings.background.destroy');
        });

        // Grading
        Route::post('/attempt-type', [AttemptTypeController::class, 'store'])->name('attempt-type.store');
        Route::post('/attempt-answer/{attemptAnswer}/re-evaluate-ai', [AttemptAnswerController::class, 'reEvaluateAi'])->name('attempt-answer.re-evaluate-ai');
    });

    /*
    | Mock exam day: Admin + Reception (docs/desktop/ARCHITECTURE.md role matrix).
    */
    Route::middleware('role:Admin|Reception|SuperAdmin')->group(function () {
        Route::post('/mock-student', [MockStudentController::class, 'store'])->name('mock-student.store');
        Route::post('/mock-student/check-repeats', [MockStudentController::class, 'checkRepeats'])->name('mock-student.check-repeats');
        Route::get('/mock/{mock}/code-cards', [MockStudentController::class, 'codeCards'])->name('mock.code-cards');
        Route::get('/mock/{mock}/code-tickets', [MockStudentController::class, 'codeTickets'])->name('mock.code-tickets');

        Route::get('/reception', [ReceptionController::class, 'index'])->name('reception.index');
        Route::post('/reception/candidates/{mockStudent}/check-in', [ReceptionController::class, 'checkIn'])->name('reception.check-in');
        Route::post('/reception/candidates/{mockStudent}/deliver', [ReceptionController::class, 'deliver'])->name('reception.deliver');
        Route::get('/reception/result-sheets', [ReceptionController::class, 'resultSheets'])->name('reception.result-sheets');

        Route::get('/monitor', [MonitorController::class, 'index'])->name('monitor.index');
    });
});

/*
|--------------------------------------------------------------------------
| Exam room: logged-in users OR candidate-code sessions.
| Every endpoint authorizes against the attempt (AttemptPolicy).
|--------------------------------------------------------------------------
*/

Route::middleware([EnsureCandidateOrAuthenticated::class])->group(function () {
    Route::get('practice', [PracticeController::class, 'index'])->name('practice.index');
    Route::get('practice-attempt/{attempt}', [PracticeController::class, 'practice_attempt'])->name('practice-attempt');
    Route::get('practice-test-type/{test_type}', [PracticeController::class, 'practice_test_type'])->name('practice-test-type');
    Route::get('practice-part/{part}', [PracticeController::class, 'practice_part'])->name('practice-part');

    Route::post('practice-attempt-submit/{attempt}', [PracticeController::class, 'submit'])->name('practice-attempt-submit');
    Route::post('practice-test-type-submit/{attempt}/{type_id}', [PracticeController::class, 'submit_test_type'])->name('practice-test-type-submit');
    Route::post('practice-attempt-violation/{attempt}', [PracticeController::class, 'recordViolation'])->name('practice-attempt-violation');

    Route::get('attempt-part', [AttemptPartController::class, 'index'])->name('attempt-part.index');
    Route::post('attempt-answer', [AttemptAnswerController::class, 'store'])->name('attempt-answer.store');

    Route::get('media/audio/{filename}', [MediaController::class, 'audio'])
        ->where('filename', '[A-Za-z0-9._-]+')
        ->name('media.audio');
});

/*
|--------------------------------------------------------------------------
| Live monitor actions (desktop exam). Admin; remote unlock also Reception.
| Rules: docs/desktop/ARCHITECTURE.md, API.md "Admin-side".
|--------------------------------------------------------------------------
*/

Route::middleware(['auth', 'verified', 'center.active'])->prefix('monitor/attempts/{attempt}')->name('monitor.')->group(function () {
    Route::middleware('role:Admin|SuperAdmin')->group(function () {
        Route::post('extra-time', [MonitorController::class, 'extraTime'])->name('extra-time');
        Route::post('pause', [MonitorController::class, 'pause'])->name('pause');
        Route::post('resume', [MonitorController::class, 'resume'])->name('resume');
        Route::post('force-submit', [MonitorController::class, 'forceSubmit'])->name('force-submit');
    });

    Route::post('unlock', [MonitorController::class, 'unlock'])
        ->middleware('role:Admin|Reception|SuperAdmin')
        ->name('unlock');
    Route::post('release-device', [MonitorController::class, 'releaseDevice'])
        ->middleware('role:Admin|Reception|SuperAdmin')
        ->name('release-device');
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';

/*
|--------------------------------------------------------------------------
| Social login
|--------------------------------------------------------------------------
*/

Route::get('/auth/google', [GoogleAuthController::class, 'redirect'])->name('google.redirect');
Route::get('/auth/google/callback', [GoogleAuthController::class, 'callback'])->name('google.callback');

Route::get('/auth/github', [GithubAuthController::class, 'redirect'])->name('github.redirect');
Route::get('/auth/github/callback', [GithubAuthController::class, 'callback'])->name('github.callback');

Route::any('/auth/telegram/callback', [TelegramLoginController::class, 'handle'])->name('telegram.callback');
