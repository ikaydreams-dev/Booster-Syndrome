#include <iostream>
#include <cstring>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

class UDPSocket {
private:
    int sock_fd;
    struct sockaddr_in server_addr;
    struct sockaddr_in client_addr;

public:
    UDPSocket(int port) {
        sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock_fd < 0) {
            throw std::runtime_error("Failed to create socket");
        }

        memset(&server_addr, 0, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_addr.s_addr = INADDR_ANY;
        server_addr.sin_port = htons(port);

        if (bind(sock_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
            close(sock_fd);
            throw std::runtime_error("Bind failed");
        }
    }

    std::string receive() {
        char buffer[1024];
        socklen_t len = sizeof(client_addr);

        int n = recvfrom(sock_fd, buffer, sizeof(buffer), 0,
                        (struct sockaddr*)&client_addr, &len);

        if (n < 0) {
            throw std::runtime_error("Receive failed");
        }

        buffer[n] = '\0';
        return std::string(buffer);
    }

    void send(const std::string& message) {
        sendto(sock_fd, message.c_str(), message.length(), 0,
               (struct sockaddr*)&client_addr, sizeof(client_addr));
    }

    void sendTo(const std::string& message, const std::string& ip, int port) {
        struct sockaddr_in dest_addr;
        memset(&dest_addr, 0, sizeof(dest_addr));
        dest_addr.sin_family = AF_INET;
        dest_addr.sin_port = htons(port);
        inet_pton(AF_INET, ip.c_str(), &dest_addr.sin_addr);

        sendto(sock_fd, message.c_str(), message.length(), 0,
               (struct sockaddr*)&dest_addr, sizeof(dest_addr));
    }

    ~UDPSocket() {
        close(sock_fd);
    }
};

class UDPClient {
private:
    int sock_fd;

public:
    UDPClient() {
        sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock_fd < 0) {
            throw std::runtime_error("Failed to create socket");
        }
    }

    void send(const std::string& message, const std::string& ip, int port) {
        struct sockaddr_in server_addr;
        memset(&server_addr, 0, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        inet_pton(AF_INET, ip.c_str(), &server_addr.sin_addr);

        sendto(sock_fd, message.c_str(), message.length(), 0,
               (struct sockaddr*)&server_addr, sizeof(server_addr));
    }

    std::string receive() {
        char buffer[1024];
        struct sockaddr_in from_addr;
        socklen_t len = sizeof(from_addr);

        int n = recvfrom(sock_fd, buffer, sizeof(buffer), 0,
                        (struct sockaddr*)&from_addr, &len);

        if (n < 0) {
            throw std::runtime_error("Receive failed");
        }

        buffer[n] = '\0';
        return std::string(buffer);
    }

    ~UDPClient() {
        close(sock_fd);
    }
};
