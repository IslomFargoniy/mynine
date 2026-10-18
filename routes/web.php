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
use App\Http\Controllers\FolderController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\LandingPageController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\MockController;
use App\Http\Controllers\MockStudentController;
use App\Http\Controllers\OptionController;
use App\Http\Controllers\PartController;
use App\Http\Controllers\PracticeController;
use App\Http\Controllers\QuestionController;
use App\Http\Controllers\QuestionTypeController;
use App\Http\Controllers\SectionController;
use App\Http\Controllers\SeoPageController;
use App\Http\Controllers\SitemapController;
use App\Http\Controllers\Telegram\MynineUzBotController;
use App\Http\Controllers\Telegram\TelegramController;
use App\Http\Controllers\TestController;
use App\Http\Controllers\TestImportController;
use App\Http\Controllers\TestTypeController;
use App\Http\Controllers\User\UserController;
use App\Http\Middleware\EnsureCandidateOrAuthenticated;
use App\Http\Middleware\SetLocale;
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
Route::any('/bot/webhook', [TelegramController::class, 'handle']);
Route::any('/bot/MynineUzBot/webhook', [MynineUzBotController::class, 'handle']);

// Candidate code entry (brute-force protected)
Route::match(['get', 'post'], '/mock-student/enter', [MockStudentController::class, 'enter'])
    ->middleware('throttle:10,1')
    ->name('mock-student.enter');

// PDF is reachable with a signed URL (email / Telegram) or by anyone allowed to view the attempt.
Route::get('attempt-pdf/{attempt}', [AttemptController::class, 'pdf'])->name('attempt.pdf');

Route::get('/lang/{locale}', function (string $locale) {
    abort_unless(in_array($locale, SetLocale::SUPPORTED, true), 400);
    session(['locale' => $locale]);

    return back();
});

/*
|--------------------------------------------------------------------------
| Authenticated users (students, teachers, admins)
|--------------------------------------------------------------------------
*/

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', [HomeController::class, 'index'])->name('dashboard');

    Route::resource('all-test', AllTestController::class)->only(['index', 'show']);
    Route::resource('attempt', AttemptController::class)->only(['index', 'store', 'show', 'destroy']);

    /*
    | Content management and grading: admins and teachers only.
    | Ownership (own folder / own mock) is enforced by the policies inside the controllers.
    */
    Route::middleware('role:Admin|Teacher')->group(function () {
        Route::resource('user', UserController::class);
        Route::resource('folder', FolderController::class);

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

        Route::resource('mock', MockController::class)->only(['index', 'store', 'show', 'update', 'destroy']);
        Route::post('/mock-student', [MockStudentController::class, 'store'])->name('mock-student.store');
        Route::delete('/mock-student/{mockStudent}', [MockStudentController::class, 'destroy'])->name('mock-student.destroy');

        // Grading
        Route::post('/attempt-type', [AttemptTypeController::class, 'store'])->name('attempt-type.store');
        Route::post('/attempt-answer/{attemptAnswer}/re-evaluate-ai', [AttemptAnswerController::class, 'reEvaluateAi'])->name('attempt-answer.re-evaluate-ai');
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
