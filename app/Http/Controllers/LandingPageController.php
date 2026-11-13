<?php

namespace App\Http\Controllers;

use App\Support\UserFacingError;
use App\Models\Test;

class LandingPageController extends Controller
{
    public function tests()
    {
        try {

            $tests = Test::query()
                ->with([
                    'folder',
                    'types' => function ($query) {
                        $query->whereHas('parts');
                    },
                ])
                ->withCount('attempts')
                ->practice()
                ->where('active', 1)
                ->where('open', 1)
                ->whereHas('folder', function ($query) {
                    $query->where('active', 1);
                })
                ->get();

            return response()->json([
                'data' => $tests,
                'success' => true,
                'message' => 'Attempt retrieved successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'data' => [],
                'success' => false,
                'message' => UserFacingError::message($e),
            ], 500);
        }
    }
}
