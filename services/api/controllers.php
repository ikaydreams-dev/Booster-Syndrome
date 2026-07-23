<?php

namespace Booster\Controllers;

class UserController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function index() {
        $page = $_GET['page'] ?? 1;
        $limit = $_GET['limit'] ?? 10;
        $offset = ($page - 1) * $limit;

        $stmt = $this->db->prepare("SELECT * FROM users LIMIT ? OFFSET ?");
        $stmt->execute([$limit, $offset]);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return json_encode(['users' => $users]);
    }

    public function show($id) {
        $stmt = $this->db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            http_response_code(404);
            return json_encode(['error' => 'User not found']);
        }

        return json_encode($user);
    }

    public function store() {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("INSERT INTO users (email, username, password_hash) VALUES (?, ?, ?)");
        $stmt->execute([
            $data['email'],
            $data['username'],
            password_hash($data['password'], PASSWORD_BCRYPT)
        ]);

        $userId = $this->db->lastInsertId();

        http_response_code(201);
        return json_encode(['id' => $userId]);
    }

    public function update($id) {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("UPDATE users SET first_name = ?, last_name = ? WHERE id = ?");
        $stmt->execute([
            $data['firstName'],
            $data['lastName'],
            $id
        ]);

        return $this->show($id);
    }

    public function destroy($id) {
        $stmt = $this->db->prepare("UPDATE users SET is_active = false WHERE id = ?");
        $stmt->execute([$id]);

        http_response_code(204);
        return '';
    }
}

class EventController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function store() {
        $data = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("INSERT INTO events (user_id, event_type, event_name, properties) VALUES (?, ?, ?, ?)");
        $stmt->execute([
            $data['userId'],
            $data['eventType'],
            $data['eventName'],
            json_encode($data['properties'])
        ]);

        http_response_code(201);
        return json_encode(['id' => $this->db->lastInsertId()]);
    }
}

?>
