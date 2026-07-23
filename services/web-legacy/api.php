<?php

namespace Booster\API;

class APIRouter {
    private $routes = [];

    public function get($path, $handler) {
        $this->addRoute('GET', $path, $handler);
    }

    public function post($path, $handler) {
        $this->addRoute('POST', $path, $handler);
    }

    public function put($path, $handler) {
        $this->addRoute('PUT', $path, $handler);
    }

    public function delete($path, $handler) {
        $this->addRoute('DELETE', $path, $handler);
    }

    private function addRoute($method, $path, $handler) {
        $this->routes[$method][$path] = $handler;
    }

    public function dispatch($method, $path) {
        if (isset($this->routes[$method][$path])) {
            return call_user_func($this->routes[$method][$path]);
        }
        http_response_code(404);
        return json_encode(['error' => 'Not found']);
    }
}

class Database {
    private $pdo;

    public function __construct($host, $dbname, $user, $password) {
        $dsn = "pgsql:host=$host;dbname=$dbname";
        $this->pdo = new \PDO($dsn, $user, $password);
        $this->pdo->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
    }

    public function query($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    public function execute($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute($params);
    }
}

class UserController {
    private $db;

    public function __construct(Database $db) {
        $this->db = $db;
    }

    public function getUsers() {
        $users = $this->db->query("SELECT * FROM users WHERE is_active = true");
        return json_encode(['users' => $users]);
    }

    public function getUser($id) {
        $user = $this->db->query("SELECT * FROM users WHERE id = ?", [$id]);
        if (empty($user)) {
            http_response_code(404);
            return json_encode(['error' => 'User not found']);
        }
        return json_encode($user[0]);
    }

    public function createUser($data) {
        $sql = "INSERT INTO users (email, username, password_hash) VALUES (?, ?, ?)";
        $this->db->execute($sql, [
            $data['email'],
            $data['username'],
            password_hash($data['password'], PASSWORD_BCRYPT)
        ]);
        return json_encode(['success' => true]);
    }
}

class Cache {
    private $redis;

    public function __construct($host, $port) {
        $this->redis = new \Redis();
        $this->redis->connect($host, $port);
    }

    public function get($key) {
        return $this->redis->get($key);
    }

    public function set($key, $value, $ttl = 3600) {
        return $this->redis->setex($key, $ttl, $value);
    }

    public function delete($key) {
        return $this->redis->del($key);
    }
}

?>
