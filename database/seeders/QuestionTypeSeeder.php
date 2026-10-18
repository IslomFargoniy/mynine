<?php

namespace Database\Seeders;

use App\Models\QuestionType;
use Illuminate\Database\Seeder;

class QuestionTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $types = [
            [
                'name' => 'Multiple Choice',
                'type' => 'multiple_choice',
                'input_type' => 'radio',
            ],
            [
                'name' => 'Multiple Response',
                'type' => 'multiple_response',
                'input_type' => 'checkbox',
            ],
            [
                'name' => 'True / False',
                'type' => 'true_false',
                'input_type' => 'radio',
            ],
            [
                'name' => 'Yes / No',
                'type' => 'yes_no',
                'input_type' => 'radio',
            ],
            [
                'name' => 'Fill in the Blank',
                'type' => 'fill_blank',
                'input_type' => 'text',
            ],
            [
                'name' => 'Matching',
                'type' => 'matching',
                'input_type' => 'select',
            ],
            [
                'name' => 'Essay',
                'type' => 'essay',
                'input_type' => 'textarea',
            ],
            [
                'name' => 'Complete Section',
                'type' => 'complete_section',
                'input_type' => 'text',
            ],
            [
                'name' => 'Drag and drop',
                'type' => 'drag_and_drop',
                'input_type' => 'text',
            ],
            //            [
            //                'name' => 'Speaking',
            //                'type' => 'speaking',
            //                'input_type' => 'audio',
            //            ],
        ];

        foreach ($types as $type) {
            QuestionType::firstOrCreate(
                ['type' => $type['type']], // Unique key for lookup
                $type                      // Values to insert if not found
            );
        }
    }
}
