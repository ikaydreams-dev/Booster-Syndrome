import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.*;

public class WebServer {

    public static class HTTPServer {
        private ServerSocket serverSocket;
        private ExecutorService threadPool;
        private Map<String, Route> routes;
        private List<Middleware> middlewares;
        private boolean running;

        public HTTPServer(int port, int poolSize) throws IOException {
            this.serverSocket = new ServerSocket(port);
            this.threadPool = Executors.newFixedThreadPool(poolSize);
            this.routes = new ConcurrentHashMap<>();
            this.middlewares = new ArrayList<>();
            this.running = false;
        }

        public void use(Middleware middleware) {
            middlewares.add(middleware);
        }

        public void get(String path, Handler handler) {
            routes.put("GET:" + path, new Route("GET", path, handler));
        }

        public void post(String path, Handler handler) {
            routes.put("POST:" + path, new Route("POST", path, handler));
        }

        public void put(String path, Handler handler) {
            routes.put("PUT:" + path, new Route("PUT", path, handler));
        }

        public void delete(String path, Handler handler) {
            routes.put("DELETE:" + path, new Route("DELETE", path, handler));
        }

        public void start() {
            running = true;
            System.out.println("Server started on port " + serverSocket.getLocalPort());

            while (running) {
                try {
                    Socket clientSocket = serverSocket.accept();
                    threadPool.submit(() -> handleClient(clientSocket));
                } catch (IOException e) {
                    if (running) {
                        e.printStackTrace();
                    }
                }
            }
        }

        public void stop() throws IOException {
            running = false;
            serverSocket.close();
            threadPool.shutdown();
        }

        private void handleClient(Socket clientSocket) {
            try (BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                 PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true)) {

                Request request = parseRequest(in);
                Response response = new Response();

                for (Middleware middleware : middlewares) {
                    middleware.handle(request, response);
                }

                Route route = findRoute(request.getMethod(), request.getPath());

                if (route != null) {
                    route.handler.handle(request, response);
                } else {
                    response.setStatus(404);
                    response.setBody("Not Found");
                }

                sendResponse(out, response);

            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
                    clientSocket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        private Request parseRequest(BufferedReader in) throws IOException {
            String requestLine = in.readLine();
            if (requestLine == null) {
                return new Request("GET", "/", new HashMap<>(), "");
            }

            String[] parts = requestLine.split(" ");
            String method = parts[0];
            String path = parts[1];

            Map<String, String> headers = new HashMap<>();
            String line;
            while ((line = in.readLine()) != null && !line.isEmpty()) {
                int colonIndex = line.indexOf(':');
                if (colonIndex > 0) {
                    String key = line.substring(0, colonIndex).trim();
                    String value = line.substring(colonIndex + 1).trim();
                    headers.put(key, value);
                }
            }

            StringBuilder body = new StringBuilder();
            if (headers.containsKey("Content-Length")) {
                int contentLength = Integer.parseInt(headers.get("Content-Length"));
                char[] buffer = new char[contentLength];
                in.read(buffer, 0, contentLength);
                body.append(buffer);
            }

            return new Request(method, path, headers, body.toString());
        }

        private void sendResponse(PrintWriter out, Response response) {
            out.println("HTTP/1.1 " + response.getStatus() + " " + getStatusMessage(response.getStatus()));

            for (Map.Entry<String, String> header : response.getHeaders().entrySet()) {
                out.println(header.getKey() + ": " + header.getValue());
            }

            out.println();
            out.println(response.getBody());
            out.flush();
        }

        private String getStatusMessage(int status) {
            switch (status) {
                case 200: return "OK";
                case 201: return "Created";
                case 204: return "No Content";
                case 400: return "Bad Request";
                case 401: return "Unauthorized";
                case 403: return "Forbidden";
                case 404: return "Not Found";
                case 500: return "Internal Server Error";
                default: return "Unknown";
            }
        }

        private Route findRoute(String method, String path) {
            return routes.get(method + ":" + path);
        }
    }

    public static class Request {
        private String method;
        private String path;
        private Map<String, String> headers;
        private String body;
        private Map<String, String> params;
        private Map<String, String> queryParams;

        public Request(String method, String path, Map<String, String> headers, String body) {
            this.method = method;
            this.path = parsePath(path);
            this.headers = headers;
            this.body = body;
            this.params = new HashMap<>();
            this.queryParams = parseQueryParams(path);
        }

        private String parsePath(String fullPath) {
            int queryIndex = fullPath.indexOf('?');
            return queryIndex > 0 ? fullPath.substring(0, queryIndex) : fullPath;
        }

        private Map<String, String> parseQueryParams(String fullPath) {
            Map<String, String> params = new HashMap<>();
            int queryIndex = fullPath.indexOf('?');

            if (queryIndex > 0 && queryIndex < fullPath.length() - 1) {
                String queryString = fullPath.substring(queryIndex + 1);
                String[] pairs = queryString.split("&");

                for (String pair : pairs) {
                    String[] keyValue = pair.split("=");
                    if (keyValue.length == 2) {
                        params.put(keyValue[0], keyValue[1]);
                    }
                }
            }

            return params;
        }

        public String getMethod() { return method; }
        public String getPath() { return path; }
        public Map<String, String> getHeaders() { return headers; }
        public String getBody() { return body; }
        public Map<String, String> getParams() { return params; }
        public Map<String, String> getQueryParams() { return queryParams; }

        public String getHeader(String key) {
            return headers.get(key);
        }

        public String getParam(String key) {
            return params.get(key);
        }

        public String getQueryParam(String key) {
            return queryParams.get(key);
        }
    }

    public static class Response {
        private int status;
        private Map<String, String> headers;
        private String body;

        public Response() {
            this.status = 200;
            this.headers = new HashMap<>();
            this.body = "";
            headers.put("Content-Type", "text/html");
        }

        public void setStatus(int status) {
            this.status = status;
        }

        public void setHeader(String key, String value) {
            headers.put(key, value);
        }

        public void setBody(String body) {
            this.body = body;
        }

        public void json(Object data) {
            headers.put("Content-Type", "application/json");
            // Simplified JSON conversion
            this.body = data.toString();
        }

        public void redirect(String location) {
            this.status = 302;
            headers.put("Location", location);
        }

        public int getStatus() { return status; }
        public Map<String, String> getHeaders() { return headers; }
        public String getBody() { return body; }
    }

    public static class Route {
        String method;
        String path;
        Handler handler;

        public Route(String method, String path, Handler handler) {
            this.method = method;
            this.path = path;
            this.handler = handler;
        }
    }

    @FunctionalInterface
    public interface Handler {
        void handle(Request request, Response response);
    }

    @FunctionalInterface
    public interface Middleware {
        void handle(Request request, Response response);
    }

    public static class Router {
        private Map<String, Route> routes;
        private String prefix;

        public Router(String prefix) {
            this.routes = new HashMap<>();
            this.prefix = prefix;
        }

        public void get(String path, Handler handler) {
            String fullPath = prefix + path;
            routes.put("GET:" + fullPath, new Route("GET", fullPath, handler));
        }

        public void post(String path, Handler handler) {
            String fullPath = prefix + path;
            routes.put("POST:" + fullPath, new Route("POST", fullPath, handler));
        }

        public Map<String, Route> getRoutes() {
            return routes;
        }
    }

    public static class Session {
        private Map<String, Object> data;
        private String id;

        public Session(String id) {
            this.id = id;
            this.data = new ConcurrentHashMap<>();
        }

        public void set(String key, Object value) {
            data.put(key, value);
        }

        public Object get(String key) {
            return data.get(key);
        }

        public void remove(String key) {
            data.remove(key);
        }

        public void clear() {
            data.clear();
        }

        public String getId() {
            return id;
        }
    }

    public static class SessionManager {
        private Map<String, Session> sessions;

        public SessionManager() {
            this.sessions = new ConcurrentHashMap<>();
        }

        public Session create() {
            String id = UUID.randomUUID().toString();
            Session session = new Session(id);
            sessions.put(id, session);
            return session;
        }

        public Session get(String id) {
            return sessions.get(id);
        }

        public void destroy(String id) {
            sessions.remove(id);
        }
    }

    public static class StaticFileHandler implements Handler {
        private String root;

        public StaticFileHandler(String root) {
            this.root = root;
        }

        @Override
        public void handle(Request request, Response response) {
            String path = request.getPath();
            File file = new File(root + path);

            if (file.exists() && file.isFile()) {
                try {
                    String content = readFile(file);
                    response.setBody(content);
                    response.setHeader("Content-Type", getContentType(file));
                } catch (IOException e) {
                    response.setStatus(500);
                    response.setBody("Internal Server Error");
                }
            } else {
                response.setStatus(404);
                response.setBody("File Not Found");
            }
        }

        private String readFile(File file) throws IOException {
            StringBuilder content = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    content.append(line).append("\n");
                }
            }
            return content.toString();
        }

        private String getContentType(File file) {
            String name = file.getName();
            if (name.endsWith(".html")) return "text/html";
            if (name.endsWith(".css")) return "text/css";
            if (name.endsWith(".js")) return "application/javascript";
            if (name.endsWith(".json")) return "application/json";
            if (name.endsWith(".png")) return "image/png";
            if (name.endsWith(".jpg") || name.endsWith(".jpeg")) return "image/jpeg";
            return "text/plain";
        }
    }

    public static class CORSMiddleware implements Middleware {
        @Override
        public void handle(Request request, Response response) {
            response.setHeader("Access-Control-Allow-Origin", "*");
            response.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
            response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        }
    }

    public static class LoggingMiddleware implements Middleware {
        @Override
        public void handle(Request request, Response response) {
            System.out.println(new Date() + " " + request.getMethod() + " " + request.getPath());
        }
    }
}
