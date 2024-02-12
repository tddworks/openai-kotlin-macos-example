//
//  ContentView.swift
//  openai-kotlin-macos-example
//
//

import SwiftUI
import openai_client_darwin

struct ContentView: View {
    @State private var apiKey: String = ""
    @State private var url: String = "api.openai.com"
    @State private var prompt: String = "Once upon a time"
    @State private var response: String = ""
    var body: some View {
        VStack {
            GroupBox(label: Text("OpenAI Settings")) {
                TextField("API Key", text: $apiKey)
                        .padding()
                TextField("URL", text: $url)
                        .padding()
            }
            GroupBox(label: Text("OpenAI Playground")) {
                TextEditor(text: $prompt)
                        .padding()

                TextEditor(text: $response)
                        .padding()
            }
            Button("Submit") {
                let client = DarwinOpenAI(token: apiKey, url: url)
                Task { @MainActor in
                    for await response in client.streamCompletions(request: ChatCompletionRequest.Companion.shared.chatCompletionRequest(
                            messages: [ChatMessageCompanion.shared.user(content: prompt)],
                            model: "gpt-3.5-turbo")) {
                        self.response += response.content()
                    }
                }
            }
        }
                .padding()
    }
}

#Preview {
    ContentView()
}
