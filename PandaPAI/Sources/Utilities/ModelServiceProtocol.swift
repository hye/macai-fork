//
//  ModelServiceProtocol.swift
//  macai
//
//  Created by Renat on 06.09.2025.
//

import Foundation

/// 模型服務協議 - 支援本地端模型的協議
protocol ModelService {
    /// 服務名稱
    var name: String { get }

    /// 檢查模型可用性
    /// - Returns: 模型的可用性狀態
    func checkAvailability() async -> ModelAvailability

    /// 獲取支援的語言
    /// - Returns: 支援的語言列表
    func getSupportedLanguages() async -> [String]

    /// 創建模型會話
    /// - Parameters:
    ///   - instructions: 會話指令
    ///   - adapter: 可選的自定義適配器
    /// - Returns: 模型會話實例
    func createSession(instructions: String?, adapter: ModelAdapter?) async throws -> ModelSession

    /// 獲取可用模型列表
    /// - Returns: 可用模型列表
    func fetchAvailableModels() async throws -> [AIModel]

    /// 預熱模型（可選）
    /// - Parameter promptPrefix: 提示前綴
    func prewarmModel(promptPrefix: String?) async
}

/// 模型可用性狀態
enum ModelAvailability: Sendable {
    /// 模型可用
    case available
    /// 模型不可用
    case unavailable(reason: UnavailableReason)
}

/// 模型不可用原因
enum UnavailableReason: Sendable {
    /// 設備不支援
    case deviceNotEligible
    /// Apple Intelligence 未啟用
    case appleIntelligenceNotEnabled
    /// 模型尚未準備就緒
    case modelNotReady
    /// 其他原因
    case other(String)
}

/// 模型適配器協議
protocol ModelAdapter {
    /// 適配器名稱
    var name: String { get }
    /// 適配器描述
    var description: String { get }
}

/// 模型會話協議
protocol ModelSession: Sendable {
    /// 檢查是否正在回應
    var isResponding: Bool { get }

    /// 同步發送訊息
    /// - Parameters:
    ///   - prompt: 提示內容
    ///   - options: 生成選項
    /// - Returns: 模型回應
    func sendMessage(_ prompt: String, options: GenerationOptions?) async throws -> String

    /// 串流發送訊息
    /// - Parameters:
    ///   - prompt: 提示內容
    ///   - options: 生成選項
    /// - Returns: 回應串流
    func sendMessageStream(_ prompt: String, options: GenerationOptions?) async throws -> AsyncThrowingStream<String, Error>

    /// 獲取會話記錄
    /// - Returns: 會話記錄
    func getTranscript() async -> [TranscriptEntry]
}

/// 生成選項
struct GenerationOptions: Sendable {
    /// 溫度參數 (控制創意度)
    let temperature: Float?
    /// 最大 token 數
    let maxTokens: Int?

    init(temperature: Float? = nil, maxTokens: Int? = nil) {
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

/// 會話記錄條目
struct TranscriptEntry: Sendable {
    /// 條目類型
    let type: TranscriptEntryType
    /// 內容
    let content: String
    /// 時間戳
    let timestamp: Date
}

/// 會話記錄條目類型
enum TranscriptEntryType: Sendable {
    /// 使用者提示
    case prompt
    /// 模型回應
    case response
    /// 錯誤
    case error
}

/// 模型服務錯誤
enum ModelServiceError: Error {
    /// 服務不可用
    case serviceUnavailable(reason: UnavailableReason)
    /// 無效請求
    case invalidRequest(String)
    /// 生成錯誤
    case generationFailed(String)
    /// 網路錯誤
    case networkError(Error)
    /// 未知錯誤
    case unknown(String)
}

extension ModelService {
    /// 預設實現 - 可選方法
    func prewarmModel(promptPrefix: String?) async {
        // 預設不做任何事
    }
}