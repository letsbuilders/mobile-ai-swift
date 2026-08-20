//
//  AIServiceFactory.swift
//  MobileAI
//
//  Created by Marzena on 06/08/2026.
//

import Foundation
import Hub
import MLXLLM
import MLXLMCommon

public enum AIModelKind: CaseIterable, Identifiable {
    public static var allCases: [AIModelKind] {
        LLMRegistry.all().map { .mlx($0) } + [.appleIntelligence]
    }

    case appleIntelligence
    case mlx(ModelConfiguration)

    public var isDownloaded: Bool {
        switch self {
        case .appleIntelligence: true
        case .mlx(let config): config.isDownloaded
        }
    }

    public var name: String {
        switch self {
        case .mlx(let config):
            var tokens = config.name.split(separator: "/")
            tokens.removeFirst()
            return tokens.joined(separator: "/")
        default:
            return id
        }
    }

    public var id: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .mlx(let config): config.name
        }
    }
}

public class AIServiceFactory {
    public static func make(kind: AIModelKind) throws -> AIService {
        switch kind {
        case .appleIntelligence:
            if #available(iOS 26.0, *) {
                try AppleIntelligence()
            } else {
                throw AIError.notSupported("Available only for iOS 26.0+")
            }
        case .mlx(let config):
            MLXManager(config: config)
        }
    }
}

public extension LLMRegistry {
    static func all() -> [ModelConfiguration] {
        [
            codeLlama13b4bit,
            deepSeekR1_7B_4bit,
            gemma2bQuantized,
            gemma_2_2b_it_4bit,
            gemma_2_9b_it_4bit,
            gemma3_1B_qat_4bit,
            gemma3n_E4B_it_lm_bf16,
            gemma3n_E2B_it_lm_bf16,
            gemma3n_E4B_it_lm_4bit,
            gemma3n_E2B_it_lm_4bit,
            gemma4_e4b_it_4bit,
            gemma4_e2b_it_4bit,
            granite3_3_2b_4bit,
            granite_4_0_h_tiny_4bit_dwq,
            llama3_1_8B_4bit,
            llama3_2_1B_4bit,
            llama3_2_3B_4bit,
            llama3_8B_4bit,
            mistral7B4bit,
            mistralNeMo4bit,
            openelm270m4bit,
            phi3_5MoE,
            phi3_5_4bit,
            phi4bit,
            qwen205b4bit,
            qwen2_5_7b,
            qwen2_5_1_5b,
            qwen3_0_6b_4bit,
            qwen3_1_7b_4bit,
            qwen3_4b_4bit,
            qwen3_8b_4bit,
            qwen3MoE_30b_a3b_4bit,
            smolLM_135M_4bit,
            deepseek_r1_4bit,
            mimo_7b_sft_4bit,
            glm4_9b_4bit,
            acereason_7b_4bit,
            bitnet_b1_58_2b_4t_4bit,
            smollm3_3b_4bit,
            ernie_45_0_3BPT_bf16_ft,
            lfm2_1_2b_4bit,
            baichuan_m1_14b_instruct_4bit,
            exaone_4_0_1_2b_4bit,
            lille_130m_bf16,
            olmoe_1b_7b_0125_instruct_4bit,
            olmo_2_1124_7B_Instruct_4bit,
            ling_mini_2_2bit,
            lfm2_8b_a1b_3bit_mlx,
            nanochat_d20_mlx,
            gpt_oss_20b_MXFP4_Q8,
            jamba_3b,
        ]
    }
}

public extension ModelConfiguration {
    var isDownloaded: Bool {
        if let url = MLXCacheLocator.getModelDirectory(repoId: self.name) {
            return FileManager.default.fileExists(atPath: url.path)
        }
        return false
    }
}

struct MLXCacheLocator {

    /// Returns the local URL containing `config.json` if downloaded.
    static func getModelDirectory(repoId: String) -> URL? {
        let fileManager = FileManager.default
        let folderName = "models--" + repoId.replacingOccurrences(of: "/", with: "--")

        var candidatePaths: [URL] = []

        if let appCache = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            candidatePaths.append(appCache.appendingPathComponent("huggingface/hub/\(folderName)"))
        }

        #if os(macOS)
        let home = fileManager.homeDirectoryForCurrentUser
        candidatePaths.append(home.appendingPathComponent(".caches/huggingface/hub/\(folderName)"))
        candidatePaths.append(home.appendingPathComponent(".cache/huggingface/hub/\(folderName)"))
        #endif

        for basePath in candidatePaths {
            if let snapshotURL = findValidSnapshot(at: basePath) {
                return snapshotURL
            }
        }

        return nil
    }

    private static func findValidSnapshot(at repoURL: URL) -> URL? {
        let snapshotsURL = repoURL.appendingPathComponent("snapshots")
        let fm = FileManager.default

        guard fm.fileExists(atPath: snapshotsURL.path),
              let snapshots = try? fm.contentsOfDirectory(at: snapshotsURL, includingPropertiesForKeys: nil) else {
            return nil
        }

        for snapshot in snapshots {
            let configPath = snapshot.appendingPathComponent("config.json").path
            if fm.fileExists(atPath: configPath) {
                return snapshot
            }
        }
        return nil
    }
}
