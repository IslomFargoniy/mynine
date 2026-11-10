<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use OpenApi\Attributes as OA;

#[OA\Info(version: '1.0.0', title: 'Mynine API', description: 'Mynine.uz API (desktop exam client).')]
#[OA\SecurityScheme(securityScheme: 'bearerAuth', type: 'http', scheme: 'bearer')]
#[OA\Get(path: '/api/user', summary: 'Current authenticated user', security: [['bearerAuth' => []]], tags: ['Auth'], responses: [new OA\Response(response: 200, description: 'The user'), new OA\Response(response: 401, description: 'Unauthenticated')])]
abstract class Controller
{
    use AuthorizesRequests;
}
