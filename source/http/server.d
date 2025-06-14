module http.server;

import std.socket;
import std.array;
import std.stdio;
import std.logger;
import std.parallelism;
import std.conv : to;
import common.types;
import http.request;
import http.response;

class HttpServer {
    private TcpSocket socket;
    RequestHandler[string] routes;

    this(RequestHandler[string] routes) {
        this.routes = routes;
        this.socket = new TcpSocket();
        this.socket.bind(new InternetAddress("127.0.0.1", 8081));
        this.socket.listen(10);
        info("Server is running on http://127.0.0.1:8081");
        while (true) {
            // yay new friend
            Socket client = this.socket.accept();
            taskPool.put(task(() {
                this.handleClient(client);
            }));
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
            // (carter):
            // it could be that manually checking first two bytes for `\r\n` is faster.
            if (line.empty()) break;
            headers[header[0]] = header[1];
        }
        /// ew!
        auto body = cast(ubyte[])lines[1..$].join("\r\n");

        /// (carter):
        /// This is silly. Definitely an oopsie-woopsie with the current enum.
        /// Seems like a get-in-bed-and-watch-dune-and-fix-this-tomorrow-angle.
        switch (method) {
            case "GET":  return new HttpRequest(HttpRequest.Method.GET, path, httpVersion, headers);
            case "POST": return new HttpRequest(HttpRequest.Method.POST, path, httpVersion, headers);
            case "PUT":  return new HttpRequest(HttpRequest.Method.PUT, path, httpVersion, headers);
            default:     return null;
        }
        /// Only 3 requests will be supported. We won't need DELETE, since we just won't make mistakes.
        /// [__v(-_-)v__]
        return null;
    }

    private void handleClient(Socket client) {
        char[] buffer = new char[1024];
        auto r = client.receive(buffer);
        if (r == 0 || r == Socket.ERROR) {
            error("Socket error %d", r);
        }
        auto request = parseRequest(buffer[0..r].to!string);
        info("Parsed request: ", request);
        auto response = this.routes[request.path](request);
        client.send(response.serialize());
        client.close();
    }
}