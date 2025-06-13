module http.server;

import std.socket;
import std.array;
import std.stdio;
import std.logger;
import http.request;
import common.types;

class HttpServer {
    private TcpSocket socket;

    this() {
        import std.conv : to;

        this.socket = new TcpSocket();
        this.socket.bind(new InternetAddress("127.0.0.1", 8081));
        this.socket.listen(10);
        info("Server is running on http://127.0.0.1:8080");
        while (true) {
            // yay new friend
            auto client = this.socket.accept();
            // Too big
            char[] buffer = new char[1024];
            auto r = client.receive(buffer);
            // make sure friend isn't joshin' around
            if (r == 0 || r == Socket.ERROR) {
                error("Error receiving data from client");
            }
            // what'd the friend have to say?
            info("Received data from client: ", buffer[0..r].to!string);

            auto request = parseRequest(buffer[0..r].to!string);
            info("Parsed request: ", request);
            // let our friend know what's good.
            auto response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 12\r\n\r\nHello, D!";
            client.send(response);
            // wasn't a fan of them.
            client.close();
        }
    }

    private HttpRequest parseRequest(string request) {
        auto lines = request.split("\r\n");
        auto method = lines[0].split(" ")[0];
        auto path = lines[0].split(" ")[1];
        auto httpVersion = lines[0].split(" ")[2];
        Headers headers;
        foreach (line; lines[1..$]) {
            auto header = line.split(": ");
            // (carter): TODO: not adequately handling header values that contain colons
            if (header.length < 2) break;
            headers[header[0]] = header[1];
        }
        /// ew!
        auto body = cast(ubyte[])lines[1..$].join("\r\n");

        /// (carter):
        /// This is silly. Definitely an oopsie-woopsie with the current enum.
        /// Seems like a get-in-bed-and-watch-dune-and-fix-this-tomorrow-angle.
        if (method == "GET") {
            return new HttpRequest(HttpRequest.Method.GET, path, httpVersion, body);
        } else if (method == "POST") {
            return new HttpRequest(HttpRequest.Method.POST, path, httpVersion, body);
        } else if (method == "PUT") {
            return new HttpRequest(HttpRequest.Method.PUT, path, httpVersion, body);
        }
        /// Only 3 requests will be supported. We won't need DELETE, since we just won't make mistakes.
        /// [__v(-_-)v__]

        return null;
    }
}