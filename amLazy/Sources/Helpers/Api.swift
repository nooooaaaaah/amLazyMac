import Foundation
import SwiftOpenAI
import os

struct OpenAiClient {
    private let session: URLSession
    private let apiKey: String
    private let assistantID: String
    private let service: OpenAIService

    private static let logger = Logger(subsystem: "com.amLazy.OpenAiClient", category: "Network")

    init(apiKey: String, assistantID: String, service: OpenAIService) {
        self.session = URLSession(configuration: .default)
        self.apiKey = apiKey
        self.assistantID = assistantID
        self.service = service
    }

    func processInput(input: String, userEnvInstructions: String) async throws -> String {
        OpenAiClient.logger.log("Processing input: \(input)")

        do {
            let threadID = try await createThread()
            _ = try await createMessage(threadID: threadID, parameters: MessageParameter(role: .user, content: input))
            let stream = try await startThread(threadID: threadID, parameters: RunParameter(assistantID: self.assistantID))
            return try await retrieveResponse(stream: stream)
        } catch {
            OpenAiClient.logger.log("ERROR: \(error.localizedDescription)")
            throw error
        }
    }

    private func createThread() async throws -> String {
        let parameters = CreateThreadParameters()
        let thread = try await service.createThread(parameters: parameters)
        return thread.id
    }

    private func createMessage(threadID: String, parameters: MessageParameter) async throws -> String {
        let message = try await service.createMessage(threadID: threadID, parameters: parameters)
        return message.id
    }

    private func startThread(threadID: String, parameters: RunParameter) async throws -> AsyncThrowingStream<AssistantStreamEvent, Error> {
        let stream = try await service.createRunStream(threadID: threadID, parameters: parameters)
        return stream
    }

    private func retrieveResponse(stream: AsyncThrowingStream<AssistantStreamEvent, Error>) async throws -> String {
        // Iterate over each event in the stream
        var response: String = ""
        for try await result in stream {
            switch result {
            case .threadMessageDelta(let messageDelta):
                if let content = messageDelta.delta.content.first, case let .text(textContent) = content {
                    response += textContent.text.value
                }
            default:
                break
            }
        }
        if response != ""{
            return response
        }
        throw NSError(domain: "com.birdLaw.amLazy", code: 1, userInfo: [NSLocalizedDescriptionKey: "No valid textual response received from the stream."])
    }
}
