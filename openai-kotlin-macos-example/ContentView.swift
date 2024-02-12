//
//  ContentView.swift
//  openai-kotlin-macos-example
//
//

import SwiftUI
import openai_client_darwin

typealias image = openai_client_darwin.Image

struct ContentView: View {
    @State private var apiKey: String = ""
    @State private var url: String = "api.openai.com"
    @State private var prompt: String = "Once upon a time"
    @State private var response: String = ""
    @State private var generateImage: Bool = false
    @State private var generateImageModels = ["dall-e-2", "dall-e-3"]
    @State private var generateImageModel: String = "dall-e-2"
    @State private var generateImageUrl: String? = nil
    @State private var waitingForResponse: Bool = false
    var body: some View {
        VStack {
            GroupBox(label: Text("OpenAI Settings")) {
                TextField("API Key", text: $apiKey)
                TextField("URL", text: $url)
            }

            GroupBox(label: Text("OpenAI Playground")) {
                HStack {
                    Toggle("Generate Image", isOn: $generateImage)
                            .controlSize(.mini)
                            .toggleStyle(.switch)
                    if generateImage {
                        Picker("Model", selection: $generateImageModel) {
                            ForEach(generateImageModels, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    Spacer()
                }

                TextEditor(text: $prompt)

                if waitingForResponse {
                    ProgressView()
                } else if (generateImageUrl != nil) {
                    AsyncImage(url: URL(string: generateImageUrl!)) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.gray
                                ProgressView()
                            }
                        case .success(let image):
                            image.resizable()
                                    .aspectRatio(contentMode: .fit)
                        case .failure(let error):
                            Text(error.localizedDescription)
                                // use placeholder for production app
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    TextEditor(text: $response)
                }


            }
            Button("Submit") {
                sendRequest()
            }
        }
                .padding()
    }

    func sendRequest() {
        Task { @MainActor in
            do {
                let client = DarwinOpenAI(token: apiKey, url: url)
                if generateImage {
                    self.waitingForResponse = true
                    let listResponse = try await client.generate(
                            request: ImageCreate.Companion.shared.create(
                                    prompt: prompt,
                                    model: generateImageModel)
                    )

                    for imageResponse in listResponse.data {
                        if let image = imageResponse as? image {
                            // Update the UI on the main thread
                            DispatchQueue.main.async {
                                self.generateImageUrl = image.url
                                self.waitingForResponse = false
                            }
                        }
                    }
                } else {
                    for await response in client.streamCompletions(request: ChatCompletionRequest.Companion.shared.chatCompletionRequest(
                            messages: [ChatMessageCompanion.shared.user(content: prompt)],
                            model: "gpt-3.5-turbo")) {
                        self.response += response.content()
                    }
                }
            } catch {
                print("We had an error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}
