//
//  ContentView.swift
//  amLazy
//
//  Created by Noah Spielman on 4/28/24.
//

import SwiftUI
import SwiftOpenAI

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var botResponse: String = "Welcome to AI Chat Bot. Ask me anything!"

    var body: some View {
        VStack {
            Text("AI Chat Bot")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            ScrollView {
                Text(botResponse)
                    .padding()
            }

            HStack {
                TextField("Ask me anything...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Text("Send")
                }
                .padding()
            }
        }
    }

    func sendMessage() async {
        let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
        let assistantID = ProcessInfo.processInfo.environment["ASSISTANT_ID"] ?? ""

        let service = OpenAIServiceFactory.service(apiKey: apiKey)
        let client = OpenAiClient(apiKey: apiKey, assistantID: assistantID, service: service)

        do {
            let response = try await client.processInput(input: userInput, userEnvInstructions: "zsh,mac")
            DispatchQueue.main.async {
                self.botResponse = response
                self.userInput = "" // Optionally clear the input field after sending
            }
        } catch {
            print("Failed to get response: \(error)")
            DispatchQueue.main.async {
                self.botResponse = "Error: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView()
}
