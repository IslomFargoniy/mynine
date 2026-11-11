<?php

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

        // v1.1: the version gate (426) runs on login only; a running exam is never interrupted by it.
        Route::prefix('exam')->name('exam.')->group(function () {
            Route::post('login', [ExamAuthController::class, 'login'])
                ->middleware(['desktop.client', 'throttle:desktop-login'])
                ->name('login');

            Route::middleware('desktop.candidate')->group(function () {
                Route::post('logout', [ExamAuthController::class, 'logout'])->name('logout');

                Route::get('/', [ExamController::class, 'show'])->name('show');
                Route::get('prefetch', [ExamController::class, 'prefetch'])->name('prefetch');
                Route::get('parts/{part}', [ExamController::class, 'part'])->whereNumber('part')->name('part');
                Route::post('submit', [ExamController::class, 'submit'])->name('submit');
                Route::post('heartbeat', [ExamController::class, 'heartbeat'])->name('heartbeat');

                Route::post('modules/{typeId}/start', [ModuleController::class, 'start'])->whereNumber('typeId')->name('modules.start');
                Route::post('modules/{typeId}/submit', [ModuleController::class, 'submit'])->whereNumber('typeId')->name('modules.submit');

                Route::post('answers', [AnswerController::class, 'store'])->name('answers');
                Route::post('violations', [ViolationController::class, 'store'])->name('violations');

                Route::get('audio/test/{test}', [AudioController::class, 'test'])->whereNumber('test')->name('audio.test');
                Route::get('audio/part/{part}', [AudioController::class, 'part'])->whereNumber('part')->name('audio.part');
            });
        });
    });
});
