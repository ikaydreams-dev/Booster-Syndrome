<?php

namespace App\Controllers;

class RestController
{
    protected $service;

    public function __construct($service)
    {
        $this->service = $service;
    }

    public function index()
    {
        $page = $_GET['page'] ?? 1;
        $perPage = $_GET['per_page'] ?? 20;

        $items = $this->service->paginate($page, $perPage);
        $total = $this->service->count();

        return $this->jsonResponse([
            'data' => $items,
            'pagination' => [
                'page' => (int)$page,
                'per_page' => (int)$perPage,
                'total' => $total,
                'total_pages' => ceil($total / $perPage)
            ]
        ], 200);
    }

    public function show($id)
    {
        $item = $this->service->find($id);

        if (!$item) {
            return $this->jsonResponse(['error' => 'Not found'], 404);
        }

        return $this->jsonResponse($item, 200);
    }

    public function store()
    {
        $data = json_decode(file_get_contents('php://input'), true);
        $result = $this->service->create($data);

        if ($result['success']) {
            return $this->jsonResponse($result['data'], 201);
        }

        return $this->jsonResponse(['errors' => $result['errors']], 422);
    }

    public function update($id)
    {
        $data = json_decode(file_get_contents('php://input'), true);
        $result = $this->service->update($id, $data);

        if ($result['success']) {
            return $this->jsonResponse($result['data'], 200);
        }

        return $this->jsonResponse(['errors' => $result['errors']], 422);
    }

    public function destroy($id)
    {
        $result = $this->service->delete($id);

        if ($result['success']) {
            http_response_code(204);
            return;
        }

        return $this->jsonResponse(['error' => 'Not found'], 404);
    }

    protected function jsonResponse($data, $status = 200)
    {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode($data);
        return;
    }
}
