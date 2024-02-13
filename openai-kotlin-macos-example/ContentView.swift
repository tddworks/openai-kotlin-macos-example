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
    @State private var generateImageQualities = ["standard", "hd"]
    @State private var generateImageQuality: String = "standard"
    @State private var generateImageStyles = ["vivid", "natural"]
    @State private var generateImageStyle: String = "vivid"
    @State private var generateImageSizes = ["1024x1024", "1792*1024"]
    @State private var generateImageSize: String = "1024x1024"
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
                        Picker("Quality", selection: $generateImageQuality) {
                            ForEach(generateImageQualities, id: \.self) {
                                Text($0)
                            }
                        }

                        Picker("Style", selection: $generateImageStyle) {
                            ForEach(generateImageStyles, id: \.self) {
                                Text($0)
                            }
                        }

                        Picker("Size", selection: $generateImageSize) {
                            ForEach(generateImageSizes, id: \.self) {
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
                    HStack {
                        Text("Generated Image")
                        Button("Copy URL") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(generateImageUrl!, forType: .string)
                        }
                    }

                    AsyncImage(url: URL(string: generateImageUrl!)) { image in
                        image.resizable().scaledToFit()
                                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                                .frame(height: 150)
                    } placeholder: {
                        ProgressView()
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
                    do {
                        let listResponse = try await client.generate(
                                request: ImageCreate.Companion.shared.create(
                                        prompt: prompt,
                                        model: generateImageModel,
                                        size: generateImageSize,
                                        style: generateImageStyle,
                                        quality: generateImageQuality
                                )
                        )

                        for imageResponse in listResponse.data {
                            if let image = imageResponse as? image {
                                DispatchQueue.main.async {
                                    self.generateImageUrl = image.url
                                    self.waitingForResponse = false
                                }
                            }
                        }
                    } catch {
                        // Handle any errors here
                        print("Error generating image: \(error)")
                        self.waitingForResponse = false
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
