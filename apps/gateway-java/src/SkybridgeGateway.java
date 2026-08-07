import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicLong;

public final class SkybridgeGateway {
    private static final AtomicLong REQUEST_IDS = new AtomicLong();
    private static final HttpClient HTTP = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(2))
            .build();

    private SkybridgeGateway() {
    }

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("GATEWAY_PORT", "4561"));
        String parserUrl = System.getenv().getOrDefault("PARSER_URL", "http://127.0.0.1:8080");
        int parserTimeoutMs = Integer.parseInt(System.getenv().getOrDefault("GATEWAY_PARSER_TIMEOUT_MS", "3000"));
        String revision = System.getenv().getOrDefault("IMAGE_REVISION", "dev");
        ExecutorService clients = Executors.newVirtualThreadPerTaskExecutor();

        Runtime.getRuntime().addShutdownHook(new Thread(clients::shutdown));
        try (ServerSocket server = new ServerSocket()) {
            server.bind(new InetSocketAddress("0.0.0.0", port));
            log("gateway_started", "port=" + port + " parser_url=" + parserUrl + " revision=" + revision);
            while (!server.isClosed()) {
                Socket socket = server.accept();
                clients.submit(() -> handle(socket, parserUrl, parserTimeoutMs, revision));
            }
        }
    }

    private static void handle(Socket socket, String parserUrl, int parserTimeoutMs, String revision) {
        long requestId = REQUEST_IDS.incrementAndGet();
        try (socket;
             BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
             BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()))) {
            socket.setSoTimeout(parserTimeoutMs + 2000);
            writer.write("SKYBRIDGE READY revision=" + revision + "\n");
            writer.flush();
            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("MSG ") || line.length() == 4) {
                    writer.write("ERR expected MSG <payload>\n");
                } else {
                    String payload = line.substring(4);
                    String parser = parse(parserUrl, payload, parserTimeoutMs);
                    writer.write("ACK id=" + requestId + " parser=" + parser + " " + payload + "\n");
                    log("message_acknowledged", "id=" + requestId + " bytes=" + payload.length());
                }
                writer.flush();
            }
        } catch (Exception error) {
            log("connection_failed", "id=" + requestId + " error=" + error.getClass().getSimpleName());
        }
    }

    private static String parse(String parserUrl, String payload, int timeoutMs) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create(parserUrl + "/parse"))
                .timeout(Duration.ofMillis(timeoutMs))
                .header("Content-Type", "text/plain")
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();
        HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IOException("parser returned HTTP " + response.statusCode());
        }
        return response.body().strip().replace(' ', '_');
    }

    private static void log(String event, String fields) {
        System.out.println("timestamp=" + Instant.now() + " component=gateway event=" + event + " " + fields);
    }
}