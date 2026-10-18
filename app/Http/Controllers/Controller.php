<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

/**
 * @OA\Info(
 *   title="API",
 *   version="1.0.0",
 *   description="Description of your API"
 * ),
 *
 * @OA\SecurityScheme(
 *          securityScheme="bearerAuth",
 *          type="http",
 *          scheme="bearer",
 *          bearerFormat="JWT"
 *     ),
 */
abstract class Controller
{
    use AuthorizesRequests;
}
