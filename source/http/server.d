module http.server;

import std.socket;
import std.array;
import std.stdio;
import std.parallelism;
import std.conv : to;
import std.algorithm.searching : canFind;
import std.string;
import common.types;
import http.request;
import http.response;

private struct ParsedInfo {
    HttpRequest request;
    string methodString;
}

class HttpServer {
    private TcpSocket socket;
    RequestHandler[string] routes;

    this(RequestHandler[string] routes) {
        this.routes = routes;
        this.socket = new TcpSocket();
        this.socket.bind(new InternetAddress("127.0.0.1", 8190));
        this.socket.listen(10);
        
        while (true) {
            try {
                Socket client = this.socket.accept();

                this.handleClient(client);

            } catch (SocketException e) {
                writeln("failed: ", e.msg);
            }
        }
    }

    private ParsedInfo parseRequest(string request) {
        auto lines = request.split("\r\n");
        if (lines.length < 1 || lines[0].split(" ").length < 3) {
            return ParsedInfo(null, null);
        }

        auto requestLineParts = lines[0].split(" ");
        auto methodStr = requestLineParts[0];
        auto path = requestLineParts[1];
        auto httpVersion = requestLineParts[2];
        
        Headers headers;
        for (size_t i = 1; i < lines.length; i++) {
            auto line = lines[i];
            if (line.empty) break;
            
            auto colonPos = indexOf(line, ":");
            if (colonPos > 0) {
                auto key = line[0 .. colonPos].strip();
                auto value = line[colonPos + 1 .. $].strip();
                headers[key] = value;
            }
        }
        
        ubyte[] body;

        HttpRequest.Method method;
        switch (methodStr) {
            case "GET":  method = HttpRequest.Method.GET; break;
            case "POST": method = HttpRequest.Method.POST; break;
            case "PUT":  method = HttpRequest.Method.PUT; break;
            case "OPTIONS": method = HttpRequest.Method.OPTIONS; break;
            default: return ParsedInfo(null, null);
        }
        
        auto httpRequest = new HttpRequest(method, path, httpVersion, headers);
        return ParsedInfo(httpRequest, methodStr);
    }

    private void addCorsHeaders(HttpResponse response) {
        response.addHeader("Access-Control-Allow-Origin", "*");
        response.addHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS");
        response.addHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
    }

    private void handleClient(Socket client) {
        try {
            auto requestData = appender!string;
            char[] tempBuffer = new char[4096];
            
            while (true) {
                auto bytesReceived = client.receive(tempBuffer);
                if (bytesReceived == 0 || bytesReceived == Socket.ERROR) {
                    if (bytesReceived == 0) writeln("disc");
                    else writeln("recv error.");
                    client.close();
                    return;
                }
                
                requestData.put(tempBuffer[0..bytesReceived]);
                
                if (requestData.data.canFind("\r\n\r\n")) {
                    break;
                }
            }
            
            auto requestString = requestData.data;
            if (requestString.length == 0) {
                client.close();
                return;
            }

            auto parsedInfo = parseRequest(requestString);
            auto request = parsedInfo.request;

            if (request is null) {
                auto badRequestResponse = new HttpResponse(BAD_REQUEST, null, "<h1>400 Bad Request</h1>");
                addCorsHeaders(badRequestResponse);
                client.send(badRequestResponse.serialize());
                client.close();
                return;
            }

            if (request.method == HttpRequest.Method.OPTIONS) {
                Headers corsHeaders;
                corsHeaders["Access-Control-Allow-Origin"] = "*";
                corsHeaders["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, PATCH, OPTIONS";
                corsHeaders["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Requested-With";
                corsHeaders["Access-Control-Max-Age"] = "86400";
                auto optionsResponse = new HttpResponse(OK, corsHeaders, "");
                client.send(optionsResponse.serialize());
                client.close();
                return;
            }

            string routePath = request.path;
            auto qpos = routePath.indexOf('?');
            if (qpos != -1) {
                routePath = routePath[0 .. qpos];
            }
            
            if (routePath in routes) {
                 auto response = this.routes[routePath](request);
                 addCorsHeaders(response);
                 client.send(response.serialize());
            } else {
                Headers headers;
                headers["Content-Type"] = "text/html; charset=utf-8";
                auto notFoundResponse = new HttpResponse(NOT_FOUND, headers, "<h1>404 Not Found</h1>");
                addCorsHeaders(notFoundResponse);
                client.send(notFoundResponse.serialize());
            }

        } catch (Exception e) {
            writeln("error: ", e.msg);
        } finally {
            if (client.isAlive) {
                client.close();
            }
        }
    }
}
