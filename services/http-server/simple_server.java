package com.booster.http;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.util.HashMap;
import java.util.Map;

public class SimpleHTTPServer {
    private HttpServer server;
    private Map<String, HttpHandler> routes;

    public SimpleHTTPServer(int port) throws IOException {
        server = HttpServer.create(new InetSocketAddress(port), 0);
        routes = new HashMap<>();
        server.setExecutor(null);
    }

    public void addRoute(String path, HttpHandler handler) {
        routes.put(path, handler);
        server.createContext(path, handler);
    }

    public void start() {
        server.start();
        System.out.println("Server started on port " + server.getAddress().getPort());
    }

    public void stop() {
        server.stop(0);
    }

    public static class JSONHandler implements HttpHandler {
        private String jsonResponse;

        public JSONHandler(String json) {
            this.jsonResponse = json;
        }

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, jsonResponse.getBytes().length);

            OutputStream os = exchange.getResponseBody();
            os.write(jsonResponse.getBytes());
            os.close();
        }
    }

    public static class TextHandler implements HttpHandler {
        private String textResponse;

        public TextHandler(String text) {
            this.textResponse = text;
        }

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            exchange.getResponseHeaders().set("Content-Type", "text/plain");
            exchange.sendResponseHeaders(200, textResponse.getBytes().length);

            OutputStream os = exchange.getResponseBody();
            os.write(textResponse.getBytes());
            os.close();
        }
    }

    public static void main(String[] args) throws IOException {
        SimpleHTTPServer server = new SimpleHTTPServer(8080);

        server.addRoute("/api/health", new TextHandler("OK"));
        server.addRoute("/api/status", new JSONHandler("{\"status\":\"running\"}"));

        server.start();
    }
}
