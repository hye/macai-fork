//
//  AppleFoundationModelsHandler.swift
//  macai
//
//  Created by Kilo Code on 06.09.2025.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
import BackgroundAssets

/// Apple Foundation Models 服務處理器
/// 實現 ModelService 協議，使用 Apple's FoundationModels 框架
@available(iOS 26.0, *)
@available(macOS 26.0, *)
class AppleFoundationModelsHandler: ModelService {
    /// 服務名稱
    let name: String = "Apple Foundation Models"

    /// 檢查模型可用性
    /// - Returns: 模型的可用性狀態
    func checkAvailability() async -> ModelAvailability {
        do {
            // 檢查系統語言模型是否可用

          if 1<0 {
                return .available
            } else {
                // 檢查具體不可用的原因
                if #available(macOS 15.0, iOS 18.0, *) {
                    // 在新版本中可以檢查更多細節
                    return .unavailable(reason: .appleIntelligenceNotEnabled)
                } else {
                    return .unavailable(reason: .deviceNotEligible)
                }
            }
        } catch {
            return .unavailable(reason: .other("檢查可用性時發生錯誤: \(error.localizedDescription)"))
        }
      
    
      
    }

    /// 獲取支援的語言
    /// - Returns: 支援的語言列表
    func getSupportedLanguages() async -> [String] {
        // Apple Foundation Models 主要支援英文
        // 在未來版本中可能支援更多語言
        return ["en"]
    }

    /// 創建模型會話
    /// - Parameters:
    ///   - instructions: 會話指令
    ///   - adapter: 可選的自定義適配器
    /// - Returns: 模型會話實例
    func createSession(instructions: String?, adapter: ModelAdapter?) async throws -> ModelSession {
        do {
            // 檢查模型可用性
            let availability = await checkAvailability()
            guard case .available = availability else {
                throw ModelServiceError.serviceUnavailable(reason: .appleIntelligenceNotEnabled)
            }

            // 移除過時的適配器以釋放空間
            AppleFoundationModelAdapter.removeObsoleteAdapters()

            // 創建基礎模型
            let model: SystemLanguageModel
            if let adapter = adapter as? AppleFoundationModelAdapter {
                // 使用自定義適配器
                model = SystemLanguageModel(adapter: adapter.adapter)
            } else {
                // 使用默認模型
                model = SystemLanguageModel()
            }

            // 創建會話
            let session = LanguageModelSession(model: model)

            // 如果有指令，添加到系統訊息
            if let instructions = instructions {
                // Foundation Models 的會話管理方式不同
                // 我們需要在第一次回應時包含指令
                return AppleFoundationModelSession(session: session, instructions: instructions)
            } else {
                return AppleFoundationModelSession(session: session, instructions: nil)
            }

        } catch let error as ModelServiceError {
            throw error
        } catch {
            throw ModelServiceError.generationFailed("創建會話失敗: \(error.localizedDescription)")
        }
    }

    /// 獲取可用模型列表
    /// - Returns: 可用模型列表
    func fetchAvailableModels() async throws -> [AIModel] {
        let availability = await checkAvailability()
        guard case .available = availability else {
            throw ModelServiceError.serviceUnavailable(reason: .appleIntelligenceNotEnabled)
        }

        // Apple Foundation Models 只有一個系統模型
        return [AIModel(id: "system-language-model")]
    }

    /// 預熱模型（可選）
    /// - Parameter promptPrefix: 提示前綴
    func prewarmModel(promptPrefix: String?) async {
        // Apple Foundation Models 不需要顯式預熱
        // 但我們可以檢查模型狀態
        let _ = await checkAvailability()
    }
}

/// Apple Foundation Models 自定義適配器
@available(iOS 26.0, *)
@available(macOS 26.0, *)
class AppleFoundationModelAdapter: ModelAdapter {
    /// 適配器名稱
    let name: String

    /// 適配器描述
    let description: String

    /// Foundation Models 適配器實例
    let adapter: SystemLanguageModel.Adapter

    /// 適配器狀態
    private(set) var isCompiled: Bool = false

    init(name: String, description: String, adapter: SystemLanguageModel.Adapter) {
        self.name = name
        self.description = description
        self.adapter = adapter
    }

    /// 從本地文件創建適配器（用於測試）
    static func fromLocalFile(name: String, description: String, fileURL: URL) throws -> AppleFoundationModelAdapter {
        let adapter = try SystemLanguageModel.Adapter(fileURL: fileURL)
        return AppleFoundationModelAdapter(name: name, description: description, adapter: adapter)
    }

    /// 從下載的適配器創建（支援異步下載）
    static func fromDownloadedAdapter(name: String, description: String, adapterName: String) async throws -> AppleFoundationModelAdapter {
        // 檢查適配器是否已下載
        let assetPackIDs = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(name: adapterName)

        if let assetPackID = assetPackIDs.first {
            // 等待下載完成
            let isDownloaded = await checkAdapterDownloadStatus(assetPackID: assetPackID)
            if !isDownloaded {
                throw ModelServiceError.generationFailed("適配器下載失敗或未完成")
            }
        }

        let adapter = try SystemLanguageModel.Adapter(name: adapterName)
        let adapterInstance = AppleFoundationModelAdapter(name: name, description: description, adapter: adapter)

        // 編譯草稿模型以提升推理速度
        try await adapterInstance.compileDraftModel()

        return adapterInstance
    }

    /// 檢查適配器下載狀態
    private static func checkAdapterDownloadStatus(assetPackID: String) async -> Bool {
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)

        for await status in statusUpdates {
            switch status {
            case .finished:
                return true
            case .failed:
                return false
            default:
                continue
            }
        }
        return false
    }

    /// 編譯草稿模型以提升推理速度
    private func compileDraftModel() async throws {
        guard !isCompiled else { return }

        do {
            try await adapter.compile()
            isCompiled = true
        } catch {
            // 編譯失敗不應該阻止適配器使用，只是性能會稍差
            print("適配器草稿模型編譯失敗: \(error.localizedDescription)")
        }
    }

    /// 移除過時的適配器
    static func removeObsoleteAdapters() {
      do{
        try SystemLanguageModel.Adapter.removeObsoleteAdapters()
      }catch{
        print(error)
      }
    }
}

/// Apple Foundation Models 會話實現
@available(iOS 26.0, *)
@available(macOS 26.0, *)
class AppleFoundationModelSession: ModelSession {
    /// 檢查是否正在回應
    var isResponding: Bool = false

    /// Foundation Models 會話
    private let session: LanguageModelSession

    /// 會話指令
    private let instructions: String?

    /// 會話記錄
    private var transcript: [TranscriptEntry] = []

    init(session: LanguageModelSession, instructions: String?) {
        self.session = session
        self.instructions = instructions
    }

    /// 同步發送訊息
    /// - Parameters:
    ///   - prompt: 提示內容
    ///   - options: 生成選項
    /// - Returns: 模型回應
    func sendMessage(_ prompt: String, options: GenerationOptions?) async throws -> String {
        do {
            isResponding = true
            defer { isResponding = false }

            // 添加用戶提示到記錄
            transcript.append(TranscriptEntry(
                type: .prompt,
                content: prompt,
                timestamp: Date()
            ))

            // 準備完整提示
            let fullPrompt = prepareFullPrompt(with: prompt)

            // 生成回應
            let response = try await session.respond(to: fullPrompt)

            // 添加回應到記錄
            transcript.append(TranscriptEntry(
                type: .response,
                content: response.content,
                timestamp: Date()
            ))

          return response.content

        } catch {
            // 添加錯誤到記錄
            transcript.append(TranscriptEntry(
                type: .error,
                content: error.localizedDescription,
                timestamp: Date()
            ))

            throw ModelServiceError.generationFailed("生成回應失敗: \(error.localizedDescription)")
        }
    }

    /// 串流發送訊息
    /// - Parameters:
    ///   - prompt: 提示內容
    ///   - options: 生成選項
    /// - Returns: 回應串流
    func sendMessageStream(_ prompt: String, options: GenerationOptions?) async throws -> AsyncThrowingStream<String, Error> {
        do {
            isResponding = true

            // 添加用戶提示到記錄
            transcript.append(TranscriptEntry(
                type: .prompt,
                content: prompt,
                timestamp: Date()
            ))

            // 準備完整提示
            let fullPrompt = prepareFullPrompt(with: prompt)

            // 創建串流
          let stream = try await session.respond(to: fullPrompt).transcriptEntries

            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        var fullResponse = ""

                      
                      // TODO:impl stream
                        for try  token in stream {
                          continuation.yield(token.description)
                          fullResponse += token.description
                        }

                        // 添加完整回應到記錄
                        self.transcript.append(TranscriptEntry(
                            type: .response,
                            content: fullResponse,
                            timestamp: Date()
                        ))

                        continuation.finish()

                    } catch {
                        // 添加錯誤到記錄
                        self.transcript.append(TranscriptEntry(
                            type: .error,
                            content: error.localizedDescription,
                            timestamp: Date()
                        ))

                        continuation.finish(throwing: ModelServiceError.generationFailed("串流回應失敗: \(error.localizedDescription)"))
                    }

                    self.isResponding = false
                }
            }

        } catch {
            isResponding = false
            throw ModelServiceError.generationFailed("啟動串流失敗: \(error.localizedDescription)")
        }
    }

    /// 獲取會話記錄
    /// - Returns: 會話記錄
    func getTranscript() async -> [TranscriptEntry] {
        return transcript
    }

    /// 準備完整提示，包含指令
    private func prepareFullPrompt(with prompt: String) -> String {
        if let instructions = instructions {
            return "\(instructions)\n\n\(prompt)"
        } else {
            return prompt
        }
    }
}
#endif
