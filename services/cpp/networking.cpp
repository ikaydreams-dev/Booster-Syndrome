#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <sstream>
#include <cstring>

class HTTPRequest {
public:
    std::string method;
    std::string path;
    std::string version;
    std::map<std::string, std::string> headers;
    std::string body;

    static HTTPRequest parse(const std::string& raw) {
        HTTPRequest request;
        std::istringstream stream(raw);
        std::string line;

        std::getline(stream, line);
        std::istringstream requestLine(line);
        requestLine >> request.method >> request.path >> request.version;

        while (std::getline(stream, line) && line != "\r") {
            size_t colonPos = line.find(':');
            if (colonPos != std::string::npos) {
                std::string key = line.substr(0, colonPos);
                std::string value = line.substr(colonPos + 2);
                if (!value.empty() && value.back() == '\r') {
                    value.pop_back();
                }
                request.headers[key] = value;
            }
        }

        std::string bodyLine;
        while (std::getline(stream, bodyLine)) {
            request.body += bodyLine;
        }

        return request;
    }
};

class HTTPResponse {
public:
    int statusCode;
    std::string statusMessage;
    std::map<std::string, std::string> headers;
    std::string body;

    HTTPResponse(int code = 200, const std::string& msg = "OK")
        : statusCode(code), statusMessage(msg) {
        headers["Content-Type"] = "text/html";
    }

    void setHeader(const std::string& key, const std::string& value) {
        headers[key] = value;
    }

    void setBody(const std::string& content) {
        body = content;
        headers["Content-Length"] = std::to_string(content.length());
    }

    std::string toString() const {
        std::ostringstream response;
        response << "HTTP/1.1 " << statusCode << " " << statusMessage << "\r\n";

        for (const auto& [key, value] : headers) {
            response << key << ": " << value << "\r\n";
        }

        response << "\r\n" << body;
        return response.str();
    }
};

class Router {
public:
    using Handler = std::function<HTTPResponse(const HTTPRequest&)>;

    void addRoute(const std::string& method, const std::string& path, Handler handler) {
        routes[method + ":" + path] = handler;
    }

    HTTPResponse route(const HTTPRequest& request) {
        std::string key = request.method + ":" + request.path;

        if (routes.find(key) != routes.end()) {
            return routes[key](request);
        }

        HTTPResponse response(404, "Not Found");
        response.setBody("404 - Not Found");
        return response;
    }

private:
    std::map<std::string, Handler> routes;
};

class ConnectionPool {
public:
    ConnectionPool(size_t maxConnections) : maxConnections(maxConnections) {}

    int acquire() {
        std::unique_lock<std::mutex> lock(mutex);

        condition.wait(lock, [this] { return !connections.empty() || activeConnections < maxConnections; });

        if (!connections.empty()) {
            int conn = connections.front();
            connections.pop();
            return conn;
        }

        return ++activeConnections;
    }

    void release(int connection) {
        std::lock_guard<std::mutex> lock(mutex);
        connections.push(connection);
        condition.notify_one();
    }

private:
    size_t maxConnections;
    size_t activeConnections = 0;
    std::queue<int> connections;
    std::mutex mutex;
    std::condition_variable condition;
};

class ThreadPool {
public:
    ThreadPool(size_t numThreads) : stop(false) {
        for (size_t i = 0; i < numThreads; ++i) {
            workers.emplace_back([this] {
                while (true) {
                    std::function<void()> task;

                    {
                        std::unique_lock<std::mutex> lock(queueMutex);
                        condition.wait(lock, [this] { return stop || !tasks.empty(); });

                        if (stop && tasks.empty()) {
                            return;
                        }

                        task = std::move(tasks.front());
                        tasks.pop();
                    }

                    task();
                }
            });
        }
    }

    ~ThreadPool() {
        {
            std::unique_lock<std::mutex> lock(queueMutex);
            stop = true;
        }

        condition.notify_all();

        for (std::thread& worker : workers) {
            worker.join();
        }
    }

    template<typename F>
    void enqueue(F&& task) {
        {
            std::unique_lock<std::mutex> lock(queueMutex);
            tasks.emplace(std::forward<F>(task));
        }

        condition.notify_one();
    }

private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queueMutex;
    std::condition_variable condition;
    bool stop;
};

class WebSocketFrame {
public:
    enum Opcode {
        CONTINUATION = 0x0,
        TEXT = 0x1,
        BINARY = 0x2,
        CLOSE = 0x8,
        PING = 0x9,
        PONG = 0xA
    };

    bool fin;
    Opcode opcode;
    bool masked;
    uint64_t payloadLength;
    std::vector<uint8_t> maskingKey;
    std::vector<uint8_t> payload;

    static WebSocketFrame parse(const std::vector<uint8_t>& data) {
        WebSocketFrame frame;

        frame.fin = (data[0] & 0x80) != 0;
        frame.opcode = static_cast<Opcode>(data[0] & 0x0F);
        frame.masked = (data[1] & 0x80) != 0;

        uint8_t len = data[1] & 0x7F;
        size_t offset = 2;

        if (len == 126) {
            frame.payloadLength = (data[2] << 8) | data[3];
            offset = 4;
        } else if (len == 127) {
            frame.payloadLength = 0;
            for (int i = 0; i < 8; ++i) {
                frame.payloadLength = (frame.payloadLength << 8) | data[2 + i];
            }
            offset = 10;
        } else {
            frame.payloadLength = len;
        }

        if (frame.masked) {
            frame.maskingKey.assign(data.begin() + offset, data.begin() + offset + 4);
            offset += 4;
        }

        frame.payload.assign(data.begin() + offset, data.begin() + offset + frame.payloadLength);

        if (frame.masked) {
            for (size_t i = 0; i < frame.payload.size(); ++i) {
                frame.payload[i] ^= frame.maskingKey[i % 4];
            }
        }

        return frame;
    }

    std::vector<uint8_t> serialize() const {
        std::vector<uint8_t> data;

        uint8_t byte1 = (fin ? 0x80 : 0x00) | static_cast<uint8_t>(opcode);
        data.push_back(byte1);

        uint8_t byte2 = masked ? 0x80 : 0x00;

        if (payloadLength < 126) {
            byte2 |= static_cast<uint8_t>(payloadLength);
            data.push_back(byte2);
        } else if (payloadLength < 65536) {
            byte2 |= 126;
            data.push_back(byte2);
            data.push_back((payloadLength >> 8) & 0xFF);
            data.push_back(payloadLength & 0xFF);
        } else {
            byte2 |= 127;
            data.push_back(byte2);
            for (int i = 7; i >= 0; --i) {
                data.push_back((payloadLength >> (i * 8)) & 0xFF);
            }
        }

        if (masked) {
            data.insert(data.end(), maskingKey.begin(), maskingKey.end());
        }

        data.insert(data.end(), payload.begin(), payload.end());

        return data;
    }
};

class EventLoop {
public:
    using EventHandler = std::function<void()>;

    void addEvent(const std::string& eventName, EventHandler handler) {
        std::lock_guard<std::mutex> lock(mutex);
        handlers[eventName].push_back(handler);
    }

    void emit(const std::string& eventName) {
        std::lock_guard<std::mutex> lock(mutex);

        if (handlers.find(eventName) != handlers.end()) {
            for (auto& handler : handlers[eventName]) {
                handler();
            }
        }
    }

    void run() {
        running = true;

        while (running) {
            std::unique_lock<std::mutex> lock(mutex);

            if (!eventQueue.empty()) {
                std::string event = eventQueue.front();
                eventQueue.pop();
                lock.unlock();

                emit(event);
            } else {
                lock.unlock();
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
        }
    }

    void queueEvent(const std::string& eventName) {
        std::lock_guard<std::mutex> lock(mutex);
        eventQueue.push(eventName);
    }

    void stop() {
        running = false;
    }

private:
    std::map<std::string, std::vector<EventHandler>> handlers;
    std::queue<std::string> eventQueue;
    std::mutex mutex;
    bool running = false;
};

class LoadBalancer {
public:
    void addBackend(const std::string& backend) {
        backends.push_back(backend);
    }

    std::string getNextBackend() {
        std::lock_guard<std::mutex> lock(mutex);

        if (backends.empty()) {
            return "";
        }

        std::string backend = backends[currentIndex];
        currentIndex = (currentIndex + 1) % backends.size();

        return backend;
    }

private:
    std::vector<std::string> backends;
    size_t currentIndex = 0;
    std::mutex mutex;
};

class RateLimiter {
public:
    RateLimiter(int maxRequests, int windowSeconds)
        : maxRequests(maxRequests), windowSeconds(windowSeconds) {}

    bool allowRequest(const std::string& clientId) {
        std::lock_guard<std::mutex> lock(mutex);

        auto now = std::chrono::system_clock::now();
        auto& requests = clientRequests[clientId];

        requests.erase(
            std::remove_if(requests.begin(), requests.end(),
                [this, now](const auto& time) {
                    return std::chrono::duration_cast<std::chrono::seconds>(now - time).count() > windowSeconds;
                }),
            requests.end()
        );

        if (requests.size() < maxRequests) {
            requests.push_back(now);
            return true;
        }

        return false;
    }

private:
    int maxRequests;
    int windowSeconds;
    std::map<std::string, std::vector<std::chrono::system_clock::time_point>> clientRequests;
    std::mutex mutex;
};
