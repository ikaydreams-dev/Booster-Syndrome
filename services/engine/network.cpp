#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <curl/curl.h>
#include <json/json.h>

namespace BoosterEngine {

class HTTPClient {
private:
    CURL* curl;
    std::map<std::string, std::string> headers;

    static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
        ((std::string*)userp)->append((char*)contents, size * nmemb);
        return size * nmemb;
    }

public:
    HTTPClient() {
        curl = curl_easy_init();
    }

    ~HTTPClient() {
        if (curl) {
            curl_easy_cleanup(curl);
        }
    }

    void setHeader(const std::string& key, const std::string& value) {
        headers[key] = value;
    }

    std::string get(const std::string& url) {
        if (!curl) return "";

        std::string response;
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        struct curl_slist* headerList = nullptr;
        for (const auto& header : headers) {
            std::string headerStr = header.first + ": " + header.second;
            headerList = curl_slist_append(headerList, headerStr.c_str());
        }

        if (headerList) {
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerList);
        }

        CURLcode res = curl_easy_perform(curl);

        if (headerList) {
            curl_slist_free_all(headerList);
        }

        if (res != CURLE_OK) {
            std::cerr << "CURL error: " << curl_easy_strerror(res) << std::endl;
            return "";
        }

        return response;
    }

    std::string post(const std::string& url, const std::string& data) {
        if (!curl) return "";

        std::string response;
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        CURLcode res = curl_easy_perform(curl);

        if (res != CURLE_OK) {
            std::cerr << "CURL error: " << curl_easy_strerror(res) << std::endl;
            return "";
        }

        return response;
    }
};

class APIClient {
private:
    HTTPClient httpClient;
    std::string baseURL;
    std::string apiKey;

public:
    APIClient(const std::string& url, const std::string& key = "")
        : baseURL(url), apiKey(key) {
        if (!apiKey.empty()) {
            httpClient.setHeader("Authorization", "Bearer " + apiKey);
        }
        httpClient.setHeader("Content-Type", "application/json");
    }

    Json::Value getUser(const std::string& userId) {
        std::string url = baseURL + "/users/" + userId;
        std::string response = httpClient.get(url);

        Json::Value root;
        Json::CharReaderBuilder builder;
        std::istringstream iss(response);
        std::string errs;

        if (Json::parseFromStream(builder, iss, &root, &errs)) {
            return root;
        }

        return Json::Value();
    }

    bool createEvent(const std::string& eventType, const Json::Value& properties) {
        std::string url = baseURL + "/analytics/events";

        Json::Value payload;
        payload["eventType"] = eventType;
        payload["properties"] = properties;

        Json::StreamWriterBuilder writer;
        std::string data = Json::writeString(writer, payload);

        std::string response = httpClient.post(url, data);

        return !response.empty();
    }
};

class WebSocketClient {
private:
    std::string url;
    bool connected;

public:
    WebSocketClient(const std::string& wsUrl) : url(wsUrl), connected(false) {}

    bool connect() {
        // WebSocket connection logic
        std::cout << "Connecting to " << url << std::endl;
        connected = true;
        return true;
    }

    void send(const std::string& message) {
        if (connected) {
            std::cout << "Sending: " << message << std::endl;
        }
    }

    void onMessage(std::function<void(const std::string&)> callback) {
        // Message handling
    }

    void disconnect() {
        connected = false;
        std::cout << "Disconnected" << std::endl;
    }
};

}
