//
//  MLXManager.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

public class MLXManager: Loggable, AIService {
    public static var shared = MLXManager(config: LLMRegistry.qwen3_4b_4bit)
    var config: ModelConfiguration
    var model: ModelContainer!
    var session: ChatSession!

    public init(config: ModelConfiguration) {
        self.config = config
    }

    deinit {
        Log.info(Self.self, "Deinit")
    }

    public func downloadModel(_ progressBlock: @escaping (Progress) -> Void) async throws {
        self.model = try await loadModelContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: config,
            progressHandler: { progress in
                Log.info(Self.self, "Progress \(progress.completedUnitCount)/\(progress.totalUnitCount) \(progress.fractionCompleted)")
                progressBlock(progress)
            })

        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        progressBlock(progress)
    }

    public func startSession(instructions: String) throws -> AISession {
        Log.info(Self.self, "Downloading...")
        var count = 0

        /*
        let model = try await #huggingFaceLoadModelContainer(
            configuration: phi4bit) { progress in
                count += 1
                Log.info(Self.self, "Progress \(progress)")
            }
         */
        Log.info(Self.self, "Downloading done. \(count)")

        /*
        let instructions = """
            You create Aproplan Note/Point draft fields from a user description and a catalog.
            Return ONLY one JSON object (no markdown). Stop after the first closing brace. Exact keys only:
            {"subject":string,"comment":string|null,"issueTypePath":string|null,"cellPath":string|null,"meetingLabel":string|null,"statusLabel":string|null,"dueDateOffsetDays":integer|null,"inChargeTags":[string],"isUrgent":boolean,"customFields":[{"name":string,"value":string}],"notes":string}

            Hard rules:
            - NEVER output UUIDs or YYYY-MM-DD. Use dueDateOffsetDays only when the user states a relative due date.
            - If the user does NOT mention category/lot, location/room/building, list, status, due date, or priority: that field MUST be null (or [] for customFields). Do NOT invent or copy values from memory/examples.
            - Catalog strings CHARACTER-FOR-CHARACTER when set. Never abbreviate tags. inChargeTags: at most 5 entries; never emit empty strings.
            - meetingLabel: only if user names a list; use exact catalog.meetings[].label. Do not use Current meeting unless the user refers to it.
            - statusLabel: only exact catalog.statuses[].label; Important is not a status.
            - Priority words: set customFields Priority to last matching allowedValues; isUrgent from LAST priority word (important/high/urgent/critical=true; medium/low/normal=false). If no priority mentioned: customFields=[] and isUrgent=false.
            - Subject = short title only; do not put assignee names in subject.
            - Prefer null over guessing. One object only; no trailing commas; no repeated keys.
            """
         */
        return Session(session: ChatSession(model, instructions: instructions))
    }
}

private struct Session: AISession {
    var session: ChatSession

    init(session: ChatSession) {
        self.session = session
    }

    public func respond(to prompt: String) async throws -> AIResponse {
        let response = try await self.session.respond(to: prompt)
        return AIResponse(content: response)
    }
}
