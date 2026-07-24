<?php

namespace App\Middleware;

class AuthMiddleware
{
    private $tokenManager;
    private $publicPaths = ['/auth/login', '/auth/register', '/health'];

    public function __construct($tokenManager)
    {
        $this->tokenManager = $tokenManager;
    }

    public function handle($request, $next)
    {
        $path = $request['path'] ?? $_SERVER['REQUEST_URI'];

        if ($this->isPublicPath($path)) {
            return $next($request);
        }

        $token = $this->extractToken();

        if (!$token) {
            return $this->unauthorizedResponse('No token provided');
        }

        $result = $this->tokenManager->verify($token);

        if (!$result['valid']) {
            return $this->unauthorizedResponse('Invalid token');
        }

        $request['current_user'] = $result['payload'];
        return $next($request);
    }

    private function extractToken()
    {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

        if (preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
            return $matches[1];
        }

        return null;
    }

    private function isPublicPath($path)
    {
        foreach ($this->publicPaths as $publicPath) {
            if (strpos($path, $publicPath) === 0) {
                return true;
            }
        }
        return false;
    }

    private function unauthorizedResponse($message)
    {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['error' => $message]);
        exit;
    }
}
