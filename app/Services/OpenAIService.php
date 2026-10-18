<?php

namespace App\Services;

use OpenAI;

class OpenAIService
{
    protected $client;

    public function __construct()
    {
        $this->client = OpenAI::client(config('services.openai.key'));
    }

    public function evaluateEssay(string $taskPrompt, string $questionText, string $essayText): string
    {
        $essayText = mb_substr($essayText, 0, 4000);
        $questionText = strip_tags($questionText);

        $promptText = <<<EOT
You are an IELTS examiner. Evaluate the following essay based on the four IELTS writing criteria:
1. Task Response
2. Coherence & Cohesion
3. Lexical Resource
4. Grammatical Range & Accuracy

Return a JSON object containing:
- "overall": The overall band score (0 to 9, e.g. 6.5).
- "scores": An object containing the individual criteria band scores:
  - "task_response"
  - "coherence_cohesion"
  - "lexical_resource"
  - "grammatical_range_accuracy"
- "feedback": Detailed feedback and recommendations (about 250 words) formatted in markdown.

Task: {$taskPrompt}
Question: {$questionText}
Essay: {$essayText}
EOT;

        $response = $this->client->chat()->create([
            'model' => 'gpt-4o-mini',
            'response_format' => ['type' => 'json_object'],
            'messages' => [
                ['role' => 'system', 'content' => 'You are an IELTS writing examiner. You must return your evaluation in the requested JSON structure.'],
                ['role' => 'user', 'content' => $promptText],
            ],
            'max_tokens' => 1200,
        ]);

        return $response->choices[0]->message->content ?? '{"overall": 0, "feedback": "No response from AI"}';
    }

    public function parseTestDocument(string $rawText): array
    {
        $rawText = mb_substr($rawText, 0, 15000);

        $promptText = <<<EOT
You are an expert IELTS test database parser. Your job is to parse the following raw text from an IELTS test (Reading, Listening, Writing, etc.) and extract all sections, question types, questions, and answers into a structured JSON schema.

Identify the question types from the text. The allowed question type values are:
- "multiple_choice" (One correct answer among A, B, C, D)
- "multiple_response" (Multiple correct answers among options)
- "true_false" (True / False / Not Given)
- "yes_no" (Yes / No / Not Given)
- "fill_blank" (Fill in the blanks/gaps in sentences or tables)
- "matching" (Matching headings, information, or features, e.g. matching letters A-G to questions)
- "essay" (Writing prompts/essays)
- "complete_section" (A passage with multiple inline gaps/drop-downs)
- "drag_and_drop" (Drag words into gap sentences)

For "matching" type:
- Identify the letter range options, e.g., if letters A to F are used, set "from_option" to "A" and "to_option" to "F".
- Set the correct letter (e.g., "C") in the "answer_text" field of the matching question.

For "drag_and_drop" type:
- If there are extra words (incorrect options/distractors) listed in the instructions or box, extract them into the section's "options" array as simple strings.

For "fill_blank":
- The correct text answer must be set in the question's "answer_text" field.

For Multiple Choice, Multiple Response, True/False, and Yes/No:
- Extract all option choices. Set "is_correct" to true for correct options, false otherwise.
- For True/False, extract options: "True", "False", "Not Given".
- For Yes/No, extract options: "Yes", "No", "Not Given".

Return a JSON object with a single key "sections" containing an array of sections:
{
  "sections": [
    {
      "textarea": "Instructions, passage excerpts, or title of this section. Can include clean HTML formatting.",
      "question_type": "multiple_choice",
      "from_option": "A",
      "to_option": "D",
      "options": ["Incorrect option 1", "Incorrect option 2"], // Only for drag_and_drop incorrect distractors
      "questions": [
        {
          "textarea": "Question text or number, e.g., '1. The author argues that...'",
          "answer_text": "C", // Used for matching, fill_blank, complete_section, drag_and_drop
          "options": [
            { "textarea": "First Choice", "is_correct": false },
            { "textarea": "Second Choice", "is_correct": true }
          ]
        }
      ]
    }
  ]
}

Raw Test Text:
{$rawText}
EOT;

        try {
            $response = $this->client->chat()->create([
                'model' => 'gpt-4o-mini',
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    ['role' => 'system', 'content' => 'You are a precise IELTS parser. You must parse the raw text and return your output as structured JSON matching the database schema.'],
                    ['role' => 'user', 'content' => $promptText],
                ],
                'max_tokens' => 4000,
            ]);

            $jsonString = $response->choices[0]->message->content ?? '{"sections": []}';

            return json_decode($jsonString, true) ?? ['sections' => []];
        } catch (\Exception $e) {
            return ['sections' => [], 'error' => $e->getMessage()];
        }
    }
}
