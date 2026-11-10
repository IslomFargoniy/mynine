<?php

namespace App\Services\Import;

use RuntimeException;

/**
 * The AI hit its output token limit, so the JSON is incomplete (a Reading paper is then parsed passage by passage).
 */
class AiOutputTruncatedException extends RuntimeException {}
