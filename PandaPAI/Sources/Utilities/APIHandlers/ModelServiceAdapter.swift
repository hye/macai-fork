//
//  ModelServiceAdapter.swift
//  macai
//
//  Created by Kilo Code on 06.09.2025.
//

import Foundation

/// ModelService 到 APIService 的適配器
/// 使 ModelService 能夠與現有的 ChatService/MessageManager 兼容
class ModelServiceAdapter: APIService {
    let name: String
    let baseURL: URL

    private let modelService: ModelService
    private var currentSession: ModelSession?
    private var currentAdapter: ModelAdapter?

    init(modelService: ModelService, adapter: ModelAdapter? = nil) {
        self.name = modelService.name
        self.baseURL = URL(string: "https://apple-foundation-models.local")! // 虛擬 URL
        self.modelService = modelService
        self.currentAdapter = adapter
    }

    /// 發送訊息
    /// - Parameters:
    ///   - requestMessages: 請求訊息
    ///   - temperature: 溫度參數
    ///   - completion: 完成回調
    func sendMessage(
        _ requestMessages: [[String: Any]],
        temperature: Float,
        completion: @escaping (Result<String, APIError>) -> Void
    ) {
        Task {
            do {
                // 確保會話存在
                if currentSession == nil {
                    currentSession = try await modelService.createSession(
                        instructions: extractSystemMessage(from: requestMessages),
                        adapter: currentAdapter
                    )
                }

                // 轉換訊息格式
                let prompt = convertMessagesToPrompt(requestMessages)

                // 發送訊息
                let response = try await currentSession!.sendMessage(prompt, options: nil)

                completion(.success(response))

            } catch let error as ModelServiceError {
                let apiError = ModelServiceConverters.convertModelServiceErrorToAPIError(error)
                completion(.failure(apiError))
            } catch {
                completion(.failure(.requestFailed(error)))
            }
        }
    }

    /// 串流發送訊息
    /// - Parameters:
    ///   - requestMessages: 請求訊息
    ///   - temperature: 溫度參數
    /// - Returns: 回應串流
    func sendMessageStream(_ requestMessages: [[String: Any]], temperature: Float) async throws
        -> AsyncThrowingStream<String, Error>
    {
        // 確保會話存在
        if currentSession == nil {
            currentSession = try await modelService.createSession(
                instructions: extractSystemMessage(from: requestMessages),
                adapter: currentAdapter
            )
        }

        // 轉換訊息格式
        let prompt = convertMessagesToPrompt(requestMessages)

        // 發送串流訊息
        let stream = try await currentSession!.sendMessageStream(prompt, options: nil)

        return stream
    }

    /// 獲取可用模型
    /// - Returns: AIModel 列表
    func fetchModels() async throws -> [AIModel] {
        let availability = await modelService.checkAvailability()
        return ModelServiceConverters.convertModelAvailabilityToAIModels(availability)
    }

    /// 更新適配器
    /// - Parameter adapter: 新適配器
    func updateAdapter(_ adapter: ModelAdapter?) {
        self.currentAdapter = adapter
        // 重置會話以使用新適配器
        self.currentSession = nil
    }

    /// 提取系統訊息
    private func extractSystemMessage(from messages: [[String: Any]]) -> String? {
        for message in messages {
            if let role = message["role"] as? String, role == "system",
               let content = message["content"] as? String {
                return content
            }
        }
        return nil
    }

    /// 將訊息轉換為提示
    private func convertMessagesToPrompt(_ messages: [[String: Any]]) -> String {
        var prompt = ""

        for message in messages {
            if let role = message["role"] as? String,
               let content = message["content"] as? String {

                if role == "system" {
                    prompt += "System: \(content)\n\n"
                } else if role == "user" {
                    prompt += "User: \(content)\n\n"
                } else if role == "assistant" {
                    prompt += "Assistant: \(content)\n\n"
                }
            }
        }

        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// 工廠方法：創建 ModelServiceAdapter
extension ModelServiceAdapter {
    static func create(for modelService: ModelService, adapter: ModelAdapter? = nil) -> ModelServiceAdapter {
        return ModelServiceAdapter(modelService: modelService, adapter: adapter)
    }
}