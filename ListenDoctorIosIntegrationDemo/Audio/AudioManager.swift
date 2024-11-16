//
//  AudioManager.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 5/11/24.
//

import Foundation
import AVFoundation
import SwiftUI

@Observable
class AudioManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate, ObservableObject {
    
    // MARK: - Audio properties
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private var recordingSession: AVAudioSession!
    public var recordingUrl: URL!
    
    // MARK: - State properties
    public var isRecording = false
    public var isPlaying = false
    
    // MARK: - Stream / Audio chunks properties
    public var buffer: [Data] = []
    private var lastBufferPosition: Int = 0
    private var chunksTimer: Timer?
    
    // MARK: - Audio constants
    public static let AUDIO_FILE_FORMAT = "wav"
    private let AUDIO_SAMPLE_RATE = 8000
    private let AUDIO_BIT_DEPTH = 8
    private let AUDIO_CHANNELS = 1
    private let CHUNK_DURATION = 1.0
    private let RECORDING_FILE_NAME = "recording.\(AUDIO_FILE_FORMAT)"
    private let STREAM_FILE_NAME = "stream.\(AUDIO_FILE_FORMAT)"
    
    override init() {
        
        super.init()
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // Configure the audio session with speaker output and maximum gain
            try recordingSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            // Attempt to set input gain (might not work on all devices)
            try recordingSession.setInputGain(1.0)
            
        } catch {
            
            log(.audio, .error, "Failed to set up recording session. \(error.localizedDescription)")
        }
    }
    
    func askRecordingPermissionsIfNeeded(_ completion: @escaping (Bool) -> Void) {
        
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            
            AVAudioApplication.requestRecordPermission { allowed in
                
                DispatchQueue.main.async { completion(allowed) }
            }
            
        case .denied: DispatchQueue.main.async { completion(false) }
        default: break
        }
    }

    /**
     * Starts the audio recording to a file in the app's documents directory.
     */
    func startRecordingToFile() {
        
        let audioFilename = FileHelper.getAppDocumentsDirectory().appendingPathComponent(RECORDING_FILE_NAME)
        recordingUrl = audioFilename

        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: AUDIO_SAMPLE_RATE,
            AVNumberOfChannelsKey: AUDIO_CHANNELS,
            AVLinearPCMBitDepthKey: AUDIO_BIT_DEPTH,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            isRecording = true
        } catch {
            stopRecording(success: false)
        }
    }
    
    /**
     * Starts an audio file for streaming. Runs a timer to create audio chunks.
     */
    func startAudioStream() {
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: AUDIO_SAMPLE_RATE,
                AVNumberOfChannelsKey: AUDIO_CHANNELS,
                AVLinearPCMBitDepthKey: AUDIO_BIT_DEPTH,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ] as [String : Any]
            
            audioRecorder = try AVAudioRecorder(url: FileHelper.getAppDocumentsDirectory().appendingPathComponent(STREAM_FILE_NAME), settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            // Start sending audio chunks
            chunksTimer = Timer.scheduledTimer(withTimeInterval: CHUNK_DURATION, repeats: true) { _ in
                
                self.createNewChunk()
            }
            
        } catch {
            
            log(.audio, .error, "Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    /**
     * Creates a WAV file from a given data chunk. Only used for the first chunk. Only for wav files.
     * - note: As we don't have the actual audio data, we create a placeholder WAV file with a large size.
     */
    private func createWAVFile(from chunk: Data) -> Data {
        let largePlaceholderSize = 0xFFFFFF
        let header = createWAVHeader(for: largePlaceholderSize)//chunk.count * 10)
        var wavData = Data()
        wavData.append(header)
        wavData.append(chunk)
        return wavData
    }
    
    /**
        * Creates a WAV header for a given data length.
     */
    private func createWAVHeader(for dataLength: Int) -> Data {
        let byteRate = Int(AUDIO_SAMPLE_RATE) * Int(AUDIO_CHANNELS) * (AUDIO_BIT_DEPTH / 8)
        let blockAlign = Int(AUDIO_CHANNELS) * (AUDIO_BIT_DEPTH / 8)
        let totalDataLength = dataLength + 36
        
        var header = Data()
        header.append("RIFF".data(using: .ascii)!) // ChunkID
        header.append(UInt32(totalDataLength).littleEndian.data) // ChunkSize
        header.append("WAVE".data(using: .ascii)!) // Format
        header.append("fmt ".data(using: .ascii)!) // Subchunk1ID
        header.append(UInt32(16).littleEndian.data) // Subchunk1Size
        header.append(UInt16(1).littleEndian.data) // AudioFormat (1 for PCM)
        header.append(UInt16(AUDIO_CHANNELS).littleEndian.data) // NumChannels
        header.append(UInt32(AUDIO_SAMPLE_RATE).littleEndian.data) // SampleRate
        header.append(UInt32(byteRate).littleEndian.data) // ByteRate
        header.append(UInt16(blockAlign).littleEndian.data) // BlockAlign
        header.append(UInt16(AUDIO_BIT_DEPTH).littleEndian.data) // BitsPerSample
        header.append("data".data(using: .ascii)!) // Subchunk2ID
        header.append(UInt32(dataLength).littleEndian.data) // Subchunk2Size
        
        return header
    }
    
    /**
     * Cancels the timer that creates audio chunks.
     */
    private func invalidateStreamTimer() {
        
        chunksTimer?.invalidate()
        chunksTimer = nil
    }
    
    /**
     * Creates a new audio chunk from the audio file and appends it to the buffer.
     */
    private func createNewChunk() {
        
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        
        let audioFilePath = FileHelper.getAppDocumentsDirectory().appendingPathComponent(STREAM_FILE_NAME)
        
        do {
            // Read audio data from the last position
            let isFirstChunk = lastBufferPosition == 0
            let audioData = try Data(contentsOf: audioFilePath)
            
            // Calculate chunk size based on duration, sample rate, channels, and bit depth
            let bytesPerSecond = Int(AUDIO_SAMPLE_RATE) * (AUDIO_BIT_DEPTH / 8) * Int(AUDIO_CHANNELS)
            let chunkSize = Int(CHUNK_DURATION * Double(bytesPerSecond))
            let endPosition = min(lastBufferPosition + chunkSize, audioData.count)
            guard endPosition > lastBufferPosition else { return }
            
            // Extract the audio chunk and update last position
            let chunk = audioData.subdata(in: lastBufferPosition..<endPosition)
            lastBufferPosition = endPosition
            
            if isFirstChunk {
                let wavChunk = createWAVFile(from: chunk)
                buffer.append(wavChunk)
            } else {
                buffer.append(chunk)
            }
            
        } catch {
            
            log(.audio, .error, "Failed to read audio data: \(error.localizedDescription)")
        }
    }
    
    /**
     * Stops all the audio recording.
     */
    func stopRecording(success: Bool) {
        
        guard audioRecorder != nil else {
            
            log(.audio, .error, "Audio recorder was not set it cannot be stopped.")
            return
        }
        
        audioRecorder.stop()
        audioRecorder = nil
        isRecording = false
        lastBufferPosition = 0
        buffer = []
        invalidateStreamTimer()
//        FileHelper.deleteFile(at: recordingUrl)
//        FileHelper.deleteFile(at: FileHelper.getAppDocumentsDirectory().appendingPathComponent(STREAM_FILE_NAME))
        
        if success {
            log(.audio, .debug, "Recording finished")
        } else {
            log(.audio, .error, "Recording failed")
        }
    }
    
    /**
     * Plays the recorded audio file
     */
    func playRecordedFile() {
        
        guard let audioURL = recordingUrl
        else {
            log(.audio, .error, "Audio file URL is not set.")
            return
        }
        
        guard FileManager.default.fileExists(atPath: audioURL.path)
        else {
            log(.audio, .error, "Audio file does not exist.")
            return
        }
        
        do {
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaying = true
            
        } catch {
            
            log(.audio, .error, "Failed to play audio. \(error.localizedDescription)")
        }
    }
    
    /**
     * Plays the stream audio file
     */
    func playStreamFile() {
        
        let audioURL = FileHelper.getAppDocumentsDirectory().appendingPathComponent(STREAM_FILE_NAME)
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            log(.audio, .error, "Audio file does not exist.")
            return
        }
        
        do {
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaying = true
            
        } catch {
            
            log(.audio, .error, "Failed to play audio. \(error.localizedDescription)")
        }
    }
    
    /**
     * Plays the current buffer of audio chunks.
     */
    func playBuffer() {
        
        let combinedData = buffer.reduce(Data(), +)
        
        do {
            
            audioPlayer = try AVAudioPlayer(data: combinedData)
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            audioPlayer.play()
            isPlaying = true
            
        } catch {
            log(.audio, .error, "Failed to play audio. \(error.localizedDescription)")
        }
    }
    
    /**
     * Stops the audio player.
     */
    func stopPlaying() {
        
        audioPlayer.stop()
        isPlaying = false
    }
}

