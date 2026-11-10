<?php

namespace App\Http\Requests\Concerns;

use App\Models\Mock;
use App\Models\TestType;
use App\Services\MockBankService;
use Closure;

/**
 * Mock modules: at most one ready Mock Bank module per type (Listening, Reading, Writing).
 */
trait ValidatesMockModules
{
    /**
     * @return array<string, mixed>
     */
    protected function moduleRules(bool $required): array
    {
        return [
            'require_desktop' => 'nullable|boolean',
            'speaking_starts_at' => 'nullable|date|date_format:Y-m-d H:i',
            'speaking_slot_minutes' => 'nullable|integer|min:5|max:120',
            'modules' => [$required ? 'required' : 'nullable', 'array', 'max:3', $required ? 'min:1' : 'min:0', $this->modulesAreReady(...)],
            'modules.*' => 'integer|distinct|exists:test_types,id',
        ];
    }

    protected function modulesAreReady(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_array($value) || $value === []) {
            return;
        }

        $available = app(MockBankService::class)->availableModules()->keyBy('id');

        // Modules already assigned to the mock being edited stay valid even if no longer "ready".
        $mock = $this->route('mock');
        if ($mock instanceof Mock) {
            TestType::query()->whereIn('id', $mock->modules()->pluck('test_type_id'))->get()
                ->each(fn (TestType $tt) => $available->put($tt->id, $tt));
        }
        $types = [];

        foreach ($value as $id) {
            $module = $available->get((int) $id);
            if (! $module) {
                $fail('Modul Mock Bankda tayyor (ready) holatda emas.');

                return;
            }

            $types[] = $module->type_id;
        }

        if (count($types) !== count(array_unique($types))) {
            $fail("Har bir bo'lim turidan faqat bitta modul tanlanadi.");
        }
    }

    /**
     * @return array<int>
     */
    public function moduleIds(): array
    {
        return array_map('intval', array_values(array_filter((array) $this->input('modules', []))));
    }
}
