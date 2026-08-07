#include <arpa/inet.h>
#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

namespace {
volatile std::sig_atomic_t running = 1;

void stop(int) { running = 0; }

std::string response(int status, const std::string& type, const std::string& body) {
    std::ostringstream output;
    output << "HTTP/1.1 " << status << (status == 200 ? " OK" : " Bad Request") << "\r\n"
           << "Content-Type: " << type << "\r\n"
           << "Content-Length: " << body.size() << "\r\n"
           << "Connection: close\r\n\r\n"
           << body;
    return output.str();
}

std::string field(const std::string& payload, std::size_t index) {
    std::stringstream parts(payload);
    std::string value;
    for (std::size_t current = 0; current <= index; ++current) {
        if (!std::getline(parts, value, '/')) return "unknown";
    }
    return value.empty() ? "unknown" : value;
}

std::string parse(const std::string& payload) {
    if (payload.rfind("QU/", 0) != 0) return "invalid";
    return "cpp destination=" + field(payload, 1) + " origin=" + field(payload, 2);
}

void handle(int client) {
    std::string request;
    char buffer[4096];
    ssize_t received;
    while ((received = recv(client, buffer, sizeof(buffer), 0)) > 0) {
        request.append(buffer, static_cast<std::size_t>(received));
        auto headers = request.find("\r\n\r\n");
        if (headers != std::string::npos) {
            auto lengthHeader = request.find("Content-Length:");
            std::size_t length = 0;
            if (lengthHeader != std::string::npos) {
                length = std::stoul(request.substr(lengthHeader + 15));
            }
            if (request.size() >= headers + 4 + length) break;
        }
    }

    std::string output;
    if (request.rfind("GET /healthz ", 0) == 0 || request.rfind("GET /ready ", 0) == 0) {
        output = response(200, "application/json", "{\"status\":\"ok\"}\n");
    } else if (request.rfind("POST /parse ", 0) == 0) {
        auto bodyAt = request.find("\r\n\r\n");
        std::string body = bodyAt == std::string::npos ? "" : request.substr(bodyAt + 4);
        std::string parsed = parse(body);
        output = response(parsed == "invalid" ? 400 : 200, "text/plain", parsed + "\n");
    } else {
        output = response(400, "text/plain", "supported endpoints: GET /healthz, GET /ready, POST /parse\n");
    }
    send(client, output.data(), output.size(), 0);
    close(client);
}
}  // namespace

int main() {
    const char* configuredPort = std::getenv("PARSER_PORT");
    int port = configuredPort ? std::stoi(configuredPort) : 8080;
    std::signal(SIGINT, stop);
    std::signal(SIGTERM, stop);

    int server = socket(AF_INET, SOCK_STREAM, 0);
    int reuse = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(static_cast<uint16_t>(port));
    if (bind(server, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0 || listen(server, 64) < 0) {
        std::cerr << "component=parser event=start_failed error=" << std::strerror(errno) << '\n';
        return 1;
    }
    std::cout << "component=parser event=started port=" << port << std::endl;
    while (running) {
        int client = accept(server, nullptr, nullptr);
        if (client >= 0) handle(client);
    }
    close(server);
    return 0;
}