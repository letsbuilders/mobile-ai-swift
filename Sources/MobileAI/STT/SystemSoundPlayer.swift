//
//  SystemSoundPlayer.swift
//  MobileAI
//
//  Created by Marzena on 23/07/2026.
//

#if !os(macOS)

import AudioToolbox

final class SystemSoundPlayer {
    static var shared = SystemSoundPlayer()
    private var continuation: CheckedContinuation<Void, Never>?

    func playSystemSound(soundID: SystemSoundID) async {
        await playAndWait(soundID: soundID, isAlert: false)
    }

    func playAlertSound(soundID: SystemSoundID) async {
        await playAndWait(soundID: soundID, isAlert: true)
    }

    private func playAndWait(soundID: SystemSoundID, isAlert: Bool) async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation

            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            AudioServicesAddSystemSoundCompletion(
                soundID,
                nil,
                nil,
                { soundID, clientData in
                    guard let clientData else { return }
                    let player = Unmanaged<SystemSoundPlayer>.fromOpaque(clientData).takeUnretainedValue()
                    player.completionFired(soundID: soundID)
                },
                selfPointer
            )

            if isAlert {
                AudioServicesPlayAlertSound(soundID)
            } else {
                AudioServicesPlaySystemSound(soundID)
            }
        }
    }

    private func completionFired(soundID: SystemSoundID) {
        AudioServicesRemoveSystemSoundCompletion(soundID)
        continuation?.resume()
        continuation = nil
    }
}
#endif
