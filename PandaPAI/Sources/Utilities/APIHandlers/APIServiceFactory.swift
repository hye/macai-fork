//
//  APIServiceFactory.swift
//  macai
//
//  Created by Renat on 28.07.2024.
//

import Foundation

class APIServiceFactory {
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConstants.requestTimeout
        configuration.timeoutIntervalForResource = AppConstants.requestTimeout
        return URLSession(configuration: configuration)
    }()
  
  static func createAPIService(config: APIServiceConfiguration) -> APIService {
        let configName =
            AppConstants.defaultApiConfigurations[config.name.lowercased()]?.inherits ?? config.name.lowercased()
    if #available(macOS 26.0,iOS 26.0, *) {
      if ["applefoundationmodels","apple foundation models"].contains(configName){
        let modelService = AppleFoundationModelsHandler()
        return ModelServiceAdapter.create(for: modelService)
      }
    }
        switch configName {
        case "chatgpt":
            return ChatGPTHandler(config: config, session: session)
        case "ollama":
            return OllamaHandler(config: config, session: session)
        case "claude":
            return ClaudeHandler(config: config, session: session)
        case "perplexity":
            return PerplexityHandler(config: config, session: session)
        case "gemini":
            return GeminiHandler(config: config, session: session)
        case "deepseek":
            return DeepseekHandler(config: config, session: session)
        case "openrouter":
            return OpenRouterHandler(config: config, session: session)
        case "applefoundationmodels","apple foundation models":
           return ChatGPTHandler(config: config, session: session)
        default:
            fatalError("Unsupported API service: \(config.name)")
        }
    }
}
