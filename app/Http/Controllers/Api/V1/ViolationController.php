<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\AttemptViolation;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ViolationController extends ExamApiController
{
    /**
     * POST /exam/violations — idempotent by client_uuid.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'violations' => ['required', 'array', 'min:1', 'max:200'],
            'violations.*.client_uuid' => ['nullable', 'string', 'max:64'],
            'violations.*.type' => ['required', 'string', Rule::in(AttemptViolation::TYPES)],
            'violations.*.detail' => ['nullable', 'array', 'max:20'],
            'violations.*.occurred_at' => ['required', 'date'],
        ]);

        $attempt = $this->attempt($request);
        $device = $this->device($request);
        $items = collect($data['violations']);

        $known = AttemptViolation::where('attempt_id', $attempt->id)
            ->whereIn('client_uuid', $items->pluck('client_uuid')->filter()->unique())
            ->pluck('client_uuid')
            ->flip();

        $now = now();
        $rows = [];
        foreach ($items as $item) {
            $uuid = $item['client_uuid'] ?? null;
            if ($uuid !== null && ($known->has($uuid) || isset($rows[$uuid]))) {
                continue;
            }

            $row = [
                'attempt_id' => $attempt->id,
                'device_id' => $device->id,
                'client_uuid' => $uuid,
                'type' => $item['type'],
                'detail' => isset($item['detail']) ? json_encode($item['detail']) : null,
                'occurred_at' => Carbon::parse($item['occurred_at'])->setTimezone(config('app.timezone')),
                'created_at' => $now,
                'updated_at' => $now,
            ];

            $uuid !== null ? $rows[$uuid] = $row : $rows[] = $row;
        }

        if ($rows) {
            DB::transaction(function () use ($attempt, $rows) {
                AttemptViolation::insertOrIgnore(array_values($rows));

                // Backward compatibility with the web counter.
                $focusLost = collect($rows)->where('type', 'focus_lost')->count();
                if ($focusLost > 0) {
                    $attempt->increment('tab_switch_count', $focusLost);
                }
            });
        }

        return response()->json([
            'accepted' => $items->count(),
            'server_time' => $this->serverTime(),
        ]);
    }
}
