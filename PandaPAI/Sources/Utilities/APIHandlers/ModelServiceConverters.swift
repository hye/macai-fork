//
//  ModelServiceConverters.swift
//  macai
//
//  Created by Kilo Code on 06.09.2025.
//

import Foundation

/// ModelService 類型轉換器
/// 將 ModelService 相關類型轉換為現有的 API 類型
class ModelServiceConverters {

    /// 將 ModelServiceError 轉換為 APIError
    /// - Parameter error: ModelServiceError 實例
    /// - Returns: 對應的 APIError
    static func convertModelServiceErrorToAPIError(_ error: ModelServiceError) -> APIError {
        switch error {
        case .serviceUnavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return .serverError("Apple Intelligence 未啟用")
            case .deviceNotEligible:
                return .serverError("設備不支援 Apple Intelligence")
            case .modelNotReady:
                return .serverError("模型尚未準備就緒")
            case .other(let message):
                return .serverError(message)
            }

        case .invalidRequest(let message):
            return .invalidResponse

        case .generationFailed(let message):
            return .serverError("生成失敗: \(message)")

        case .networkError(let underlyingError):
            return .requestFailed(underlyingError)

        case .unknown(let message):
            return .unknown(message)
        }
    }

    /// 將 ModelAvailability 轉換為 AIModel 列表
    /// - Parameter availability: 模型可用性狀態
    /// - Returns: AIModel 列表，如果不可用則為空列表
    static func convertModelAvailabilityToAIModels(_ availability: ModelAvailability) -> [AIModel] {
        switch availability {
        case .available:
            // Apple Foundation Models 只有一個系統模型
            return [AIModel(id: "system-language-model")]
        case .unavailable:
            return []
        }
    }

    /// 將 UnavailableReason 轉換為 APIError
    /// - Parameter reason: 不可用原因
    /// - Returns: 對應的 APIError
    static func convertUnavailableReasonToAPIError(_ reason: UnavailableReason) -> APIError {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return .serverError("Apple Intelligence 未啟用")
        case .deviceNotEligible:
            return .serverError("設備不支援 Apple Intelligence")
        case .modelNotReady:
            return .serverError("模型尚未準備就緒")
        case .other(let message):
            return .serverError(message)
        }
    }
}