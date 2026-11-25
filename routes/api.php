<?php

use App\Http\Controllers\Api\Student\AttemptController as StudentAttemptController;
use App\Http\Controllers\Api\Student\AuthController as StudentAuthController;
use App\Http\Controllers\Api\Student\TestController as StudentTestController;
use App\Http\Controllers\Api\V1\AnswerController;
use App\Http\Controllers\Api\V1\AudioController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\ExamAuthController;
use App\Http\Controllers\Api\V1\ExamController;
use App\Http\Controllers\Api\V1\ModuleController;
use App\Http\Controllers\Api\V1\ViolationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

/*
|--------------------------------------------------------------------------
| Desktop exam client API v1 — contract: docs/desktop/API.md
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->name('api.v1.')->group(function () {
    Route::post('device/register', [DeviceController::class, 'register'])
        ->middleware('throttle:desktop-register')
        ->name('device.register');

    Route::middleware(['desktop.device', 'throttle:desktop'])->group(function () {
        Route::post('device/heartbeat', [DeviceController::class, 'heartbeat'])->name('device.heartbeat');
        Route::post('device/unlock', [DeviceController::class, 'unlock'])
            ->middleware('throttle:desktop-unlock')
            ->name('device.unlock');
        Route::get('device/config', [DeviceController::class, 'config'])->name('device.config');
        Route::get('device/background', [DeviceController::class, 'background'])->name('device.background');

        // The version gate (426) runs in login, for a new start only; a running exam is never interrupted by it.
        Route::prefix('exam')->name('exam.')->group(function () {
            Route::post('login', [ExamAuthController::class, 'login'])
                ->middleware('throttle:desktop-login')
                ->name('login');

            Route::middleware('desktop.candidate')->group(function () {
                Route::post('logout', [ExamAuthController::class, 'logout'])->name('logout');

                Route::get('/', [ExamController::class, 'show'])->name('show');
                Route::get('prefetch', [ExamController::class, 'prefetch'])->name('prefetch');
                Route::get('parts/{part}', [ExamController::class, 'part'])->whereNumber('part')->name('part');
                Route::post('submit', [ExamController::class, 'submit'])->name('submit');
                Route::post('heartbeat', [ExamController::class, 'heartbeat'])->name('heartbeat');

                Route::post('modules/{typeId}/start', [ModuleController::class, 'start'])->whereNumber('typeId')->name('modules.start');
                Route::post('modules/{typeId}/audio-lag', [ModuleController::class, 'audioLag'])->whereNumber('typeId')->name('modules.audio-lag');
                Route::post('modules/{typeId}/submit', [ModuleController::class, 'submit'])->whereNumber('typeId')->name('modules.submit');

                Route::post('answers', [AnswerController::class, 'store'])->name('answers');
                Route::post('violations', [ViolationController::class, 'store'])->name('violations');

                Route::get('audio/test/{test}', [AudioController::class, 'test'])->whereNumber('test')->name('audio.test');
                Route::get('audio/part/{part}', [AudioController::class, 'part'])->whereNumber('part')->name('audio.part');
            });
        });
    });
});

/*
|--------------------------------------------------------------------------
| Mobile apps (Android, iOS) student API — contract: docs/mobile/API.md
|--------------------------------------------------------------------------
| The exam endpoints reuse the desktop controllers (modules, answers, audio): ResolveStudentAttempt sets the
| "attempt" request attribute they read.
*/

Route::prefix('v1/student')->name('api.v1.student.')->group(function () {
    Route::get('app/version', [StudentAuthController::class, 'version'])->name('app.version');

    Route::middleware('throttle:student-auth')->prefix('auth')->name('auth.')->group(function () {
        Route::post('telegram', [StudentAuthController::class, 'telegram'])->name('telegram');
        Route::post('password', [StudentAuthController::class, 'password'])->name('password');
        Route::post('google', [StudentAuthController::class, 'google'])->name('google');
        Route::post('apple', [StudentAuthController::class, 'apple'])->name('apple');
    });

    Route::middleware(['student', 'throttle:student'])->group(function () {
        Route::get('me', [StudentAuthController::class, 'me'])->name('me');
        Route::patch('me', [StudentAuthController::class, 'update'])->name('me.update');
        Route::delete('me', [StudentAuthController::class, 'destroy'])->name('me.destroy');
        Route::post('auth/logout', [StudentAuthController::class, 'logout'])->name('auth.logout');

        Route::get('tests', [StudentTestController::class, 'index'])->name('tests.index');
        Route::get('tests/{test}', [StudentTestController::class, 'show'])->whereNumber('test')->name('tests.show');

        Route::get('attempts', [StudentAttemptController::class, 'index'])->name('attempts.index');
        Route::post('attempts', [StudentAttemptController::class, 'store'])->name('attempts.store');

        Route::prefix('attempts/{attempt}')->whereNumber('attempt')->middleware('student.attempt')->name('attempts.')->group(function () {
            Route::get('/', [StudentAttemptController::class, 'show'])->name('show');
            Route::get('parts/{part}', [StudentAttemptController::class, 'part'])->whereNumber('part')->name('part');
            Route::post('modules/{typeId}/start', [ModuleController::class, 'start'])->whereNumber('typeId')->name('modules.start');
            Route::post('modules/{typeId}/submit', [ModuleController::class, 'submit'])->whereNumber('typeId')->name('modules.submit');
            Route::post('modules/{typeId}/audio-lag', [ModuleController::class, 'audioLag'])->whereNumber('typeId')->name('modules.audio-lag');
            Route::post('answers', [AnswerController::class, 'store'])->name('answers');
            Route::post('submit', [StudentAttemptController::class, 'submit'])->name('submit');
            Route::get('result', [StudentAttemptController::class, 'result'])->name('result');
            Route::get('audio/test/{test}', [AudioController::class, 'test'])->whereNumber('test')->name('audio.test');
            Route::get('audio/part/{part}', [AudioController::class, 'part'])->whereNumber('part')->name('audio.part');
        });
    });
});
