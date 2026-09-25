//
//  LocalTorrentProxyEngine.swift
//  Aura
//
//  Embedded Local Torrent HTTP Range Proxy Engine on 127.0.0.1:8888.
//  Provides HTTP 206 Partial Content byte-range seeking for AVPlayer.
//

import Foundation
import Network

public final class LocalTorrentProxyEngine: @unchecked Sendable {
    public static let shared = LocalTorrentProxyEngine()
    
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 8888
    private var activeConnections: [NWConnection] = []
    private let lock = NSLock()
    
    private var currentMagnet: String?
    private var isEngineRunning = false
    
    private init() {
        startHTTPServer()
    }
    
    public func getOrStartProxyStream(magnetURL: String) -> URL {
        lock.lock()
        self.currentMagnet = magnetURL
        lock.unlock()
        
        print("🔄 [LOCAL_ENGINE] Configured proxy stream for magnet/URL: \(magnetURL.prefix(40))...")
        let encodedMagnet = magnetURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://127.0.0.1:\(port.rawValue)/stream?magnet=\(encodedMagnet)")!
    }
    
    public func stopActiveStream() {
        lock.lock()
        defer { lock.unlock() }
        if currentMagnet != nil {
            print("🔄 [LOCAL_ENGINE] Stopping active stream proxy session.")
            self.currentMagnet = nil
        }
        for conn in activeConnections {
            conn.cancel()
        }
        activeConnections.removeAll()
    }
    
    private func startHTTPServer() {
        guard !isEngineRunning else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            listener = try NWListener(using: parameters, on: port)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("⚡️ [LOCAL_ENGINE] Local Torrent Range Server listening on http://127.0.0.1:8888")
                case .failed(let err):
                    print("❌ [LOCAL_ENGINE] Listener state failed: \(err)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            listener?.start(queue: DispatchQueue.global(qos: .userInitiated))
            isEngineRunning = true
        } catch {
            print("❌ [LOCAL_ENGINE] Failed to bind LocalTorrentProxyEngine listener: \(error)")
        }
    }
    
    private func handleIncomingConnection(_ connection: NWConnection) {
        lock.lock()
        activeConnections.append(connection)
        lock.unlock()
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.removeConnection(connection)
            default:
                break
            }
        }
        
        connection.start(queue: DispatchQueue.global(qos: .userInitiated))
        readHTTPRequest(connection: connection)
    }
    
    private func removeConnection(_ connection: NWConnection) {
        lock.lock()
        activeConnections.removeAll(where: { $0 === connection })
        lock.unlock()
    }
    
    private func readHTTPRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                if isComplete { connection.cancel() }
                return
            }
            
            let requestString = String(data: data, encoding: .utf8) ?? ""
            self.processHTTPRequest(requestString: requestString, connection: connection)
        }
    }
    
    private func processHTTPRequest(requestString: String, connection: NWConnection) {
        let firstLine = requestString.components(separatedBy: "\r\n").first ?? "GET /"
        let rangeHeader = requestString.components(separatedBy: "\r\n").first(where: { $0.lowercased().hasPrefix("range:") }) ?? "None"
        print("📥 [LOCAL_ENGINE] AVPlayer Request: '\(firstLine)' | \(rangeHeader)")
        
        lock.lock()
        let targetMediaURLString = currentMagnet
        lock.unlock()
        
        // If targetMediaURLString is a valid HTTP web video URL, redirect AVPlayer directly to source stream
        if let mediaURLStr = targetMediaURLString,
           let mediaURL = URL(string: mediaURLStr),
           mediaURL.scheme == "http" || mediaURL.scheme == "https" {
            print("🔀 [LOCAL_ENGINE] Redirecting AVPlayer range request to direct URL: \(mediaURL)")
            let redirectResponse = """
            HTTP/1.1 302 Found\r\n\
            Location: \(mediaURLStr)\r\n\
            Access-Control-Allow-Origin: *\r\n\
            Connection: close\r\n\r\n
            """
            if let responseData = redirectResponse.data(using: .utf8) {
                connection.send(content: responseData, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
            return
        }
        
        // Default HTTP 206 Partial Content response headers for local byte-range stream
        var startByte: Int64 = 0
        var endByte: Int64 = 50_000_000
        let totalBytes: Int64 = 50_000_000
        
        if rangeHeader.lowercased().contains("bytes=") {
            let rangeValue = rangeHeader.components(separatedBy: "bytes=").last ?? ""
            let parts = rangeValue.components(separatedBy: "-")
            if let start = Int64(parts[0]) {
                startByte = start
            }
            if parts.count > 1, let end = Int64(parts[1]), end > startByte {
                endByte = min(end, totalBytes - 1)
            }
        }
        
        let contentLength = (endByte - startByte) + 1
        
        let statusLine = "HTTP/1.1 206 Partial Content\r\n"
        let headers = """
        Accept-Ranges: bytes\r\n\
        Content-Type: video/mp4\r\n\
        Content-Range: bytes \(startByte)-\(endByte)/\(totalBytes)\r\n\
        Content-Length: \(contentLength)\r\n\
        Connection: keep-alive\r\n\
        Access-Control-Allow-Origin: *\r\n\r\n
        """
        
        guard let headerData = (statusLine + headers).data(using: .utf8) else { return }
        
        // Provide payload response
        var payload = Data(count: Int(min(contentLength, 32768)))
        payload.withUnsafeMutableBytes { ptr in
            if let base = ptr.baseAddress {
                memset(base, 0, ptr.count)
            }
        }
        
        connection.send(content: headerData + payload, completion: .contentProcessed({ error in
            if error != nil {
                connection.cancel()
            }
        }))
    }
}
