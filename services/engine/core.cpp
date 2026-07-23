#include <iostream>
#include <vector>
#include <memory>
#include <string>
#include <unordered_map>
#include <chrono>
#include <thread>
#include <mutex>

namespace BoosterEngine {

class Event {
public:
    std::string type;
    std::unordered_map<std::string, std::string> data;
    std::chrono::system_clock::time_point timestamp;

    Event(const std::string& t) : type(t) {
        timestamp = std::chrono::system_clock::now();
    }
};

class EventHandler {
public:
    virtual void handle(const Event& event) = 0;
    virtual ~EventHandler() = default;
};

class EventBus {
private:
    std::unordered_map<std::string, std::vector<std::shared_ptr<EventHandler>>> handlers;
    std::mutex mutex_;

public:
    void subscribe(const std::string& eventType, std::shared_ptr<EventHandler> handler) {
        std::lock_guard<std::mutex> lock(mutex_);
        handlers[eventType].push_back(handler);
    }

    void publish(const Event& event) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = handlers.find(event.type);
        if (it != handlers.end()) {
            for (auto& handler : it->second) {
                handler->handle(event);
            }
        }
    }

    void unsubscribe(const std::string& eventType) {
        std::lock_guard<std::mutex> lock(mutex_);
        handlers.erase(eventType);
    }
};

class MessageQueue {
private:
    std::vector<std::string> queue;
    std::mutex mutex_;
    size_t maxSize;

public:
    MessageQueue(size_t max = 10000) : maxSize(max) {}

    bool push(const std::string& message) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue.size() >= maxSize) {
            return false;
        }
        queue.push_back(message);
        return true;
    }

    std::string pop() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue.empty()) {
            return "";
        }
        std::string msg = queue.front();
        queue.erase(queue.begin());
        return msg;
    }

    size_t size() const {
        return queue.size();
    }

    bool empty() const {
        return queue.empty();
    }
};

class Logger {
public:
    enum Level { DEBUG, INFO, WARNING, ERROR, CRITICAL };

private:
    Level minLevel;
    std::mutex mutex_;

public:
    Logger(Level level = INFO) : minLevel(level) {}

    void log(Level level, const std::string& message) {
        if (level < minLevel) return;

        std::lock_guard<std::mutex> lock(mutex_);
        auto now = std::chrono::system_clock::now();
        auto time = std::chrono::system_clock::to_time_t(now);

        std::cout << "[" << levelToString(level) << "] "
                  << std::ctime(&time) << " - " << message << std::endl;
    }

    void debug(const std::string& msg) { log(DEBUG, msg); }
    void info(const std::string& msg) { log(INFO, msg); }
    void warning(const std::string& msg) { log(WARNING, msg); }
    void error(const std::string& msg) { log(ERROR, msg); }
    void critical(const std::string& msg) { log(CRITICAL, msg); }

private:
    std::string levelToString(Level level) {
        switch(level) {
            case DEBUG: return "DEBUG";
            case INFO: return "INFO";
            case WARNING: return "WARNING";
            case ERROR: return "ERROR";
            case CRITICAL: return "CRITICAL";
            default: return "UNKNOWN";
        }
    }
};

class ThreadPool {
private:
    std::vector<std::thread> workers;
    bool stop;

public:
    ThreadPool(size_t threads) : stop(false) {
        for (size_t i = 0; i < threads; ++i) {
            workers.emplace_back([this] {
                while (!stop) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }
            });
        }
    }

    ~ThreadPool() {
        stop = true;
        for (std::thread& worker : workers) {
            if (worker.joinable()) {
                worker.join();
            }
        }
    }
};

}
