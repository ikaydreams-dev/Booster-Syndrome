<?php

class RESTfulAPI {
    private $routes = [];
    private $middleware = [];

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

    public function patch($path, $handler) {
        $this->addRoute('PATCH', $path, $handler);
    }

    private function addRoute($method, $path, $handler) {
        $pattern = $this->pathToPattern($path);
        $this->routes[] = [
            'method' => $method,
            'pattern' => $pattern,
            'handler' => $handler,
            'path' => $path
        ];
    }

    private function pathToPattern($path) {
        $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[^/]+)', $path);
        return '#^' . $pattern . '$#';
    }

    public function use($middleware) {
        $this->middleware[] = $middleware;
    }

    public function run() {
        $method = $_SERVER['REQUEST_METHOD'];
        $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

        $request = new Request($method, $path);
        $response = new Response();

        foreach ($this->middleware as $mw) {
            $mw($request, $response);
        }

        foreach ($this->routes as $route) {
            if ($route['method'] === $method && preg_match($route['pattern'], $path, $matches)) {
                $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
                $request->params = $params;

                $handler = $route['handler'];
                $handler($request, $response);
                return;
            }
        }

        $response->status(404)->json(['error' => 'Not Found']);
    }
}

class Request {
    public $method;
    public $path;
    public $params = [];
    public $query = [];
    public $body;
    public $headers = [];

    public function __construct($method, $path) {
        $this->method = $method;
        $this->path = $path;
        $this->query = $_GET;
        $this->headers = getallheaders();
        $this->parseBody();
    }

    private function parseBody() {
        $contentType = $this->headers['Content-Type'] ?? '';

        if (strpos($contentType, 'application/json') !== false) {
            $this->body = json_decode(file_get_contents('php://input'), true);
        } else {
            $this->body = $_POST;
        }
    }

    public function input($key, $default = null) {
        return $this->body[$key] ?? $default;
    }

    public function query($key, $default = null) {
        return $this->query[$key] ?? $default;
    }

    public function header($key, $default = null) {
        return $this->headers[$key] ?? $default;
    }
}

class Response {
    private $statusCode = 200;
    private $headers = [];

    public function status($code) {
        $this->statusCode = $code;
        return $this;
    }

    public function header($key, $value) {
        $this->headers[$key] = $value;
        return $this;
    }

    public function json($data) {
        $this->header('Content-Type', 'application/json');
        $this->send(json_encode($data));
    }

    public function send($data) {
        http_response_code($this->statusCode);

        foreach ($this->headers as $key => $value) {
            header("$key: $value");
        }

        echo $data;
    }
}

class Validator {
    public static function validate($data, $rules) {
        $errors = [];

        foreach ($rules as $field => $ruleSet) {
            $ruleList = explode('|', $ruleSet);

            foreach ($ruleList as $rule) {
                $error = self::applyRule($field, $data[$field] ?? null, $rule);
                if ($error) {
                    $errors[$field][] = $error;
                }
            }
        }

        return empty($errors) ? null : $errors;
    }

    private static function applyRule($field, $value, $rule) {
        if ($rule === 'required' && empty($value)) {
            return "$field is required";
        }

        if (str_starts_with($rule, 'min:')) {
            $min = (int)substr($rule, 4);
            if (strlen($value) < $min) {
                return "$field must be at least $min characters";
            }
        }

        if (str_starts_with($rule, 'max:')) {
            $max = (int)substr($rule, 4);
            if (strlen($value) > $max) {
                return "$field must be at most $max characters";
            }
        }

        if ($rule === 'email' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            return "$field must be a valid email";
        }

        if ($rule === 'numeric' && !is_numeric($value)) {
            return "$field must be numeric";
        }

        return null;
    }
}

class Database {
    private $pdo;

    public function __construct($dsn, $username, $password) {
        $this->pdo = new PDO($dsn, $username, $password);
        $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    }

    public function query($sql, $params = []) {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function insert($table, $data) {
        $columns = implode(', ', array_keys($data));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));

        $sql = "INSERT INTO $table ($columns) VALUES ($placeholders)";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_values($data));

        return $this->pdo->lastInsertId();
    }

    public function update($table, $data, $where) {
        $set = implode(', ', array_map(fn($col) => "$col = ?", array_keys($data)));
        $whereClause = implode(' AND ', array_map(fn($col) => "$col = ?", array_keys($where)));

        $sql = "UPDATE $table SET $set WHERE $whereClause";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_merge(array_values($data), array_values($where)));

        return $stmt->rowCount();
    }

    public function delete($table, $where) {
        $whereClause = implode(' AND ', array_map(fn($col) => "$col = ?", array_keys($where)));

        $sql = "DELETE FROM $table WHERE $whereClause";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_values($where));

        return $stmt->rowCount();
    }
}

?>
