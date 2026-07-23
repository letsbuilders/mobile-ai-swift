//
//  SpeechEngine.swift
//  AproplanAI
//
//  Created by Marzena on 07/07/2026.
//

#if !os(macOS)
import Speech

public extension SpeechEngine {
    enum ServiceError: Error {
        case recognizerNotAvailable
        case alreadyTranscribing
    }
}

public actor SpeechEngine: ObservableObject, Loggable {
    var task: SFSpeechRecognitionTask?
    var audioSession = AVAudioSession.sharedInstance()
    var engine = AVAudioEngine()
    var request: SFSpeechAudioBufferRecognitionRequest?
    var recognizer: SFSpeechRecognizer?
    private var isTranscribing = false

    public init(locale: Locale) throws {
        audioSession = AVAudioSession.sharedInstance()

        engine = AVAudioEngine()
        guard let speechRecognizer = SFSpeechRecognizer(locale: locale), speechRecognizer.isAvailable else {
            throw ServiceError.recognizerNotAvailable
        }
        recognizer = speechRecognizer
    }

    public func transcribe(onReady: @escaping () async -> Void = {},
                           onResult: @escaping (String, Bool) -> Void) async throws -> Result<String, Error> {
        guard !isTranscribing else {
            error("Already transcribing")
            return .failure(ServiceError.alreadyTranscribing)
        }

        guard let recognizer else {
            error("No recognizer")
            return .success("")
        }

        isTranscribing = true

        info("Create audio session")

        try await checkTime("Audio session") {
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                throw(error)
            }
        }

        request = try await checkTime("Create request") {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            return request
        }

        guard let request else {
            error("No request")
            return .success("")
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        await checkTime("Install tap") {
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { buffer, time in
                request.append(buffer)
            }
        }

        await checkTime("Prepare engine") {
            engine.prepare()
        }

        try await checkTime("Start engine") {
            try engine.start()
        }

        await onReady()

        let result = try await withCheckedContinuation { (continuation: CheckedContinuation<Result<String, Error>, Never>) in
            info("Start listening")
            var finalText = ""

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self, isTranscribing else { return }

                info("-- Recognition callback (\(result?.isFinal), \(error))")
                if let error {
                    self.error(error, in: "recognition task callback")
                    continuation.resume(returning: .failure(error))
                } else if let result {
                    var text = result.bestTranscription.formattedString
                    info("Result (\(result.isFinal)). \(text)")

                    onResult(text, result.isFinal)

                    if result.isFinal {
                        info("Finish: \(finalText)")
                        continuation.resume(returning: .success(finalText))
                    } else {
                        finalText = text
                    }
                }
            }
        }

        defer {
            isTranscribing = false
            info("Recognition task finished: \(result)")
            stop()
        }

        return result
    }

    public func stop() {
        print("Stop recognizer")

        self.engine.stop()
        self.engine.inputNode.removeTap(onBus: 0)

        self.request?.endAudio()
        self.request = nil
        self.task = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

}

@available(iOS 26.0, *)
public class BetterSpeechEngine {
    init() async throws {
        let transcriber = SpeechTranscriber(locale: .current, preset: .transcription)
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await installationRequest.downloadAndInstall()
        }
    }
}
#endif
