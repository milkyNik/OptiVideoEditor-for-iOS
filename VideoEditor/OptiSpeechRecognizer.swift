//
//  OptiSpeechRecognizer.swift
//  Marvel Editor
//
//  Created by dev on 10.01.2025.
//  Copyright © 2025 optisol. All rights reserved.
//

import Speech

enum OptiSpeechRecognizerStatus {
    case enabled
    case disabled
}

protocol OptiSpeechRecognizerDelegate: class {
    func didRecieveAuthorizationStatus(_ status: OptiSpeechRecognizerStatus)
    func didRecognizeText(text: String)
}

class OptiSpeechRecognizer {

    weak var delegate: OptiSpeechRecognizerDelegate?

    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                self?.delegate?.didRecieveAuthorizationStatus(.enabled)
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                self?.delegate?.didRecieveAuthorizationStatus(.disabled)
                print("Speech recognition not authorized")
            @unknown default:
                fatalError()
            }
        }
    }

    /// Initiates speech recognition using the device's microphone.
    ///
    /// This method configures and starts the audio engine to capture audio input
    /// and process it for speech recognition in real-time. The recognized text
    /// is delivered through the delegate pattern.
    ///
    /// The method performs the following steps:
    /// 1. Sets up the audio engine and recognition request
    /// 2. Configures the input node for audio capture
    /// 3. Creates a recognition task to process the audio
    /// 4. Installs an audio tap to receive audio buffers
    /// 5. Starts the audio engine
    ///
    /// - Note: Make sure the app has microphone permission before calling this method
    ///
    /// - Important: The recognition will continue until an error occurs,
    ///             the final result is received, or `stopTranscription()` is called
    ///
    /// - Throws: Errors related to:
    ///   - Audio engine initialization
    ///   - Audio session configuration
    ///   - Recognition request setup
    ///
    /// - SeeAlso: `stopTranscription()`
    /// - SeeAlso: `OptiSpeechRecognizerDelegate`
    func startTranscription() {

        print("startTranscription")

        let audioEngine = AVAudioEngine()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        recognitionRequest?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) {
            [weak self] result, error in

            if let err = error {
                print("Error recognizing speech: \(err.localizedDescription)")
            }

            if let result = result {
                self?.delegate?.didRecognizeText(text: result.bestTranscription.formattedString)
                print(
                    "Transcription: \(result.bestTranscription.formattedString) result: \(result.isFinal)"
                )
            }

            if error != nil || result?.isFinal == true {

                print("Transcription stopped")

                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    /// Stops the ongoing speech recognition process.
    ///
    /// This method terminates the current speech recognition session by ending
    /// the audio input processing. It safely closes the recognition request
    /// and releases associated resources.
    ///
    /// - Note: This method should be called when:
    ///   - Speech recognition is no longer needed
    ///   - Before starting a new recognition session
    ///   - When cleaning up resources
    ///
    /// - Important: Calling this method while no recognition is in progress is safe
    ///             and will have no effect
    ///
    /// - SeeAlso: `startTranscription()`
    func stopTranscription() {
        recognitionRequest?.endAudio()
    }
}
