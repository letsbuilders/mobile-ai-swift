//
//  SpeachRecognizer.swift
//  AproplanAI
//
//  Created by Marzena on 06/07/2026.
//
#if !os(macOS)
import Speech
import SwiftUI

public final class SpeechRecognizerState: ObservableObject {
    @Published public var isAvailable = false
    @Published public var isAuthorized = false
    @Published public var isRecording = false

    public nonisolated init() {}
}

public final actor SpeechRecognizer: Sendable, Loggable {
    public static let shared = SpeechRecognizer()

    @MainActor var state = SpeechRecognizerState()

    var engine: SpeechEngine?

    private var recognizer: SFSpeechRecognizer?
    private var inactivtyTimer = InactivityTimer()
    private var isTranscribing: Bool = false

    private init(locale: Locale = .current) {
        do {
            engine = try? SpeechEngine(locale: locale)
            let isAvailable = engine != nil
            Task { @MainActor in
                state.isAvailable = isAvailable
            }
        } catch {
            self.error(error)
        }
    }

    public func transcribe() async throws -> String {
        guard let engine, !isTranscribing else {
            return ""
        }

        isTranscribing = true

        await inactivtyTimer.start(inactivity: 2.0) {
            self.info("Inavity detected. Cancel")
            Task {
                await engine.stop()
            }
        }

        defer {
            Task {
                await inactivtyTimer.invalidate()
            }
            isTranscribing = false
        }

        info("Start")
        let result = try await engine.transcribe(onReady: { @MainActor @Sendable in
            self.state.isRecording = true
        }, onResult: { @Sendable (text, isFinished) in
            Log.info(Self.self, "Result \(isFinished): \(text)")

            Task {
                await self.inactivtyTimer.updateLastDate(.now)
            }
        })

        await MainActor.run {
            self.state.isRecording = false
        }

        info("End: \(result)")

        switch result {
        case .success(let text): return text
        case .failure(let error): throw error
        }
    }

    public func startRecording() async {

    }

    @MainActor
    public func requestAuthorization() async -> Bool {
        let isGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("Speech authorization status: \(status)")
                if status == .authorized {
                    AVAudioApplication.requestRecordPermission { isGranted in
                        print("Recording permission: \(isGranted)")
                        continuation.resume(returning: isGranted)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }

        await createRecognizer()

        await MainActor.run {
            state.isAuthorized = isGranted
        }

        return isGranted
    }

    private func createRecognizer() {
        self.recognizer = SFSpeechRecognizer(locale: .current)
    }
}

final actor InactivityTimer: Sendable, Loggable {
    @MainActor private var timer: Timer?
    private var lastDate: Date?

    deinit {
        Task { @MainActor [weak self] in
            self?.timer?.invalidate()
        }
    }

    func updateLastDate(_ date: Date) {
        info("Update date \(date)")
        self.lastDate = date
    }

    func start(inactivity: TimeInterval, _ onInactivity: @escaping @MainActor () -> Void) {
        lastDate = nil

        Task { @MainActor in
            if timer != nil {
                await invalidate()
            }

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
                guard let self, let lastDate else { return }
                if Date.now.timeIntervalSince(lastDate) > inactivity {
                    info("Inavity detected")
                    onInactivity()
                    Task {
                        await self.invalidate()
                    }
                }
            })
        }
    }

    func invalidate() async {
        info("Invalidate timer")

        await MainActor.run {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
#endif
