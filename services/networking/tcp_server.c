#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT 8080
#define BUFFER_SIZE 1024
#define MAX_CLIENTS 10

typedef struct {
    int socket_fd;
    struct sockaddr_in address;
    int running;
} tcp_server_t;

tcp_server_t* tcp_server_create(int port) {
    tcp_server_t* server = malloc(sizeof(tcp_server_t));

    server->socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server->socket_fd < 0) {
        perror("Socket creation failed");
        free(server);
        return NULL;
    }

    int opt = 1;
    setsockopt(server->socket_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    server->address.sin_family = AF_INET;
    server->address.sin_addr.s_addr = INADDR_ANY;
    server->address.sin_port = htons(port);

    if (bind(server->socket_fd, (struct sockaddr*)&server->address, sizeof(server->address)) < 0) {
        perror("Bind failed");
        close(server->socket_fd);
        free(server);
        return NULL;
    }

    if (listen(server->socket_fd, MAX_CLIENTS) < 0) {
        perror("Listen failed");
        close(server->socket_fd);
        free(server);
        return NULL;
    }

    server->running = 1;
    return server;
}

void handle_client(int client_fd) {
    char buffer[BUFFER_SIZE] = {0};
    int bytes_read = read(client_fd, buffer, BUFFER_SIZE);

    if (bytes_read > 0) {
        printf("Received: %s\n", buffer);

        char* response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello from C TCP Server";
        write(client_fd, response, strlen(response));
    }

    close(client_fd);
}

void tcp_server_run(tcp_server_t* server) {
    printf("TCP Server listening on port %d\n", PORT);

    while (server->running) {
        struct sockaddr_in client_addr;
        socklen_t addr_len = sizeof(client_addr);

        int client_fd = accept(server->socket_fd, (struct sockaddr*)&client_addr, &addr_len);

        if (client_fd < 0) {
            perror("Accept failed");
            continue;
        }

        handle_client(client_fd);
    }
}

void tcp_server_destroy(tcp_server_t* server) {
    server->running = 0;
    close(server->socket_fd);
    free(server);
}
