//
//  SocketManager.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 4/11/24.
//

import Foundation
import SocketIO

@Observable
class WSManager: ObservableObject {
    
    var socketManager: SocketManager!
    var socket: SocketIOClient!
    
    var isConnected: Bool = false
    var isInRoom: Bool = false
    var transcription = ""
    var summary = ""
    
    init(url: URL, socket: SocketIOClient? = nil) {
        
        // Initialize the socket manager WITHOUT TOKEN. The token will be passed when connecting.
        self.socketManager = SocketManager(socketURL: url)
        self.socket = socket ?? socketManager.defaultSocket
        subscribeToEvents()
    }
    
    /**
     * Connect to the socket.
     * - Parameter token: The token to authenticate the connection.
     * - warning: This method should be called after the socket has been initialized.
     * - warning: The token must be a valid JWT token.
     */
    func connect(_ token: String) {
        
        socket.connect(withPayload: ["authorization" : "Bearer \(token)"])
    }
    
    /**
     * Disconnect from the socket.
     */
    public func disconnect() {
        
        socket.disconnect()
    }
    
    /**
     * Subscribe to the socket events. This is necessary to listen to the events emitted by the server.
     * - warning: This method should be called after the socket has been initialized and before connecting to the socket.
     */
    private func subscribeToEvents() {
        
        // This event is emitted when the client has successfully connected to the server.
        socket.on(clientEvent: .connect)
        { [unowned self] data, ack in
            log(.sockets, .debug, "Socket connected")
            isConnected = true
            joinRoom()
        }
        
        // This event is emitted when the client has successfully joined a room.
        socket.on("room_joined")
        { [unowned self] data, ack in
            log(.sockets, .debug, "Joined room: \(data)")
            isInRoom = true
        }
        
        // This event is emitted when the server has finished processing the audio stream.
        // The server will respond with a transcription and a summary of the audio.
        socket.on("processing_complete")
        { [unowned self] data, ack in
            log(.sockets, .debug, "Processing complete with data: \(data)")
            guard let dic = data.first as? [String: Any] else { return }
            let transcription = dic["transcription"] as? String ?? ""
            self.transcription = transcription
            let summary = dic["summary"] as? String ?? ""
            self.summary = summary
        }
        
        // This event is emitted when user has been disconnected from the server.
        socket.on(clientEvent: .disconnect)
        { [unowned self] data, ack in
            log(.sockets, .debug, "Socket disconnected. Data: \(data)")
            isConnected = false
            isInRoom = false
            transcription = ""
            summary = ""
        }
        
        // This event is emitted when there is an error with the socket.
        socket.on(clientEvent: .error)
        { data, ack in
            log(.sockets, .error, "Socket error: \(([data][0] as? Error)?.localizedDescription ?? (data as? [String])?.first ?? "Unknown error")")
        }
        
        // This event is emitted when the server has started recording the stream.
        socket.on("recording_started")
        { data, ack in
            log(.sockets, .debug, "Recording started. Data: \(data)")
        }
    }
    
    /**
     * This will notify the server that the client wants to join a room.
     * - note: The server will respond with a "room_joined" event in the subscribed events
     */
    private func joinRoom() {
        socket.emit("join_room", ["room": UUID().uuidString])
    }
    
    /**
     * This will notify the server that a new stream is being started. The server will then start recording the stream.
     * - Parameter username: The username of the user starting the stream.
     * - Parameter fileExtension: The file extension of the stream.
     * - Parameter language: The language of the stream.
     * - Parameter prompt: The prompt of the stream.
     * - Parameter speciality: The speciality of the stream.
     * - Parameter category: The category of the stream.
     * - note: The server will respond with a "recording_started" event in the subscribed events.
     */
    func startNewStream(username: String, fileExtension: String, language: String, prompt: String, speciality: String, category: String) {
        
        let df = DateFormatter()
        df.dateFormat = "dd MMMM yyyy, HH:mm"
        
        socket
            .emit("start_recording",
                  ["username": username,
                   "fileExtension": fileExtension,
                   "config": ["language": language,
                              "prompt": prompt,
                              "speciality": speciality,
                              "category": category,
                              "datetime": df.string(from: Date.now)
                             ]
                  ]
            )
    }
    
    /**
     * This will notify the server that the stream is ending. The server will then stop recording the stream.
     * - note: The server will respond with an "processing_complete" event when ending the stream.
     */
    func endStream() {
        socket.emit("stop_recording")
    }
    
    /**
     * Sends a 'blob' of audio data to the server. The first chunk should include file header depending on the file format.
     * - Parameter chunk: The audio chunk to send.
     * - note: If something goes wrong, the server will respond in this emit callback with an error message.
     * - note: The server will respond with an "processing_complete" event when ending the stream.
     */
    func sendAudioChunk(_ chunk: Data) {
        
        socket.emitWithAck("audio_chunk", chunk).timingOut(after: 0)
        { data in
            
            if let response = data.first as? [String: Any],
               let status = response["status"] as? String,
               status == "success"
            {
                log(.sockets, .debug, "Audio chunk sent successfully")
                
            } else if let response = data.first as? [String: Any],
                      let error = response["error"] as? String
            {
                log(.sockets, .error, "Error sending audio chunk: \(error)")
            }
        }
    }
}

