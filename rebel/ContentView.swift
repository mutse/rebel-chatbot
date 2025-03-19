//
//  ContentView.swift
//  rebel
//
//  Created by Mutse Yang on 8/3/25.
//

import SwiftUI
import Combine


// MARK: - DeepSeek API 模型

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekRequest: Codable {
    let model: String
    let messages: [DeepSeekMessage]
    let stream: Bool
    let temperature: Float
    let max_tokens: Int
}

struct DeepSeekResponse: Codable {
    let id: String
    let model: String
    let choices: [DeepSeekChoice]
    
    struct DeepSeekChoice: Codable {
        let message: DeepSeekMessage
        let finish_reason: String?
    }
}

enum DeepSeekError: Error, Equatable {
    case invalidFormat
    case networkError
    case apiError(String)
    
    static func == (lhs: DeepSeekError, rhs: DeepSeekError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidFormat, .invalidFormat):
            return true
        case (.networkError, .networkError):
            return true
        case (.apiError(let lhsMessage), .apiError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - DeepSeek API 服务

class DeepSeekService: ObservableObject {
    @AppStorage("apiKey") private var apiKey: String = "YOUR_API_KEY" // 请替换为实际的 API 密钥
    @AppStorage("baseURl") private var baseURL = "https://openrouter.ai/api/v1/chat/completions"
    @AppStorage("model") private var model_name: String = "deepseek/deepseek-r1:free"
    @Published var isLoading = false
    @Published var error: String?
    
    func sendMessage(messages: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let deepseekMessages = messages.map { DeepSeekMessage(
            role: $0.isUser ? "user" : "assistant",
            content: $0.content
        )}
        
        let request = DeepSeekRequest(
            model: model_name, // 或根据需要选择具体的模型
            messages: deepseekMessages,
            stream: false,
            temperature: 0.7,
            max_tokens: 1000
        )
        
        // 创建 URL 请求
        guard let url = URL(string: baseURL) else {
            completion(.failure(DeepSeekError.apiError("无效的 URL")))
            isLoading = false
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            completion(.failure(DeepSeekError.invalidFormat))
            isLoading = false
            return
        }
        
        // 执行请求
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(.failure(DeepSeekError.networkError))
                    return
                }
                
                guard let data = data else {
                    let error = DeepSeekError.apiError("没有返回数据")
                    self?.error = "抱歉，发生了错误：The data couldn't be read because it isn't in the correct format."
                    completion(.failure(error))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
                    if let messageContent = response.choices.first?.message.content {
                        completion(.success(messageContent))
                    } else {
                        throw DeepSeekError.apiError("返回数据格式错误")
                    }
                } catch {
                    self?.error = "抱歉，发生了错误：The data couldn't be read because it isn't in the correct format."
                    completion(.failure(DeepSeekError.invalidFormat))
                }
            }
        }.resume()
    }
}

// MARK: - 聊天模型

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isLoading: Bool = false
}

// MARK: - 聊天视图模型

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    @Published var selectedLanguage = "汉语"
    
    private let deepSeekService = DeepSeekService()
    
    init() {
        // 初始化欢迎消息
        addAssistantMessage("你好! 我是 DeepSeek AI 助手，有什么可以帮助你的?")
    }
    
    func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(content: newMessage, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        // 添加一个加载中的消息占位符
        let loadingMessage = ChatMessage(content: "", isUser: false, timestamp: Date(), isLoading: true)
        messages.append(loadingMessage)
        
        let userInput = newMessage
        newMessage = ""
        
        // 模拟 API 错误或调用 DeepSeek API
        if userInput == "你是谁?" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                // 移除加载中的消息
                self?.messages.removeAll { $0.isLoading }
                self?.addAssistantMessage("抱歉，发生了错误：The data couldn't be read because it isn't in the correct format.")
            }
        } else {
            // 调用 DeepSeek API
            deepSeekService.sendMessage(messages: messages.filter { !$0.isLoading }) { [weak self] result in
                DispatchQueue.main.async {
                    // 移除加载中的消息
                    self?.messages.removeAll { $0.isLoading }
                    
                    switch result {
                    case .success(let response):
                        self?.addAssistantMessage(response)
                    case .failure(let error):
                        if let deepSeekError = error as? DeepSeekError, deepSeekError == DeepSeekError.invalidFormat {
                            self?.addAssistantMessage("抱歉，发生了错误：The data couldn't be read because it isn't in the correct format.")
                        } else {
                            self?.addAssistantMessage("抱歉，发生了错误：\(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func addAssistantMessage(_ content: String) {
        let assistantMessage = ChatMessage(content: content, isUser: false, timestamp: Date())
        messages.append(assistantMessage)
    }
}

// MARK: - 主内容视图

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingLanguageSelector = false
    @State private var showingSidebar = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {  
            // 头部
            HStack {
                Button(action: {
                    showingSidebar.toggle()
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                
                Text("Deep AI Chatbot")
                    .font(.system(size: 22, weight: .bold))
                
                Spacer()

                Button(action: {
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                
                Button(action: {
                    // 新建聊天
                    viewModel.messages = []
                    viewModel.addAssistantMessage("你好! 我是 DeepSeek AI 助手，有什么可以帮助你的?")
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                
                Button(action: {
                    // 导出操作
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                
                Button(action: {
                    // 历史记录操作
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 15)
            
            Divider()
            
            // 语言选择器
            HStack(spacing: 15) {
                Text("R1")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(30)
                
                Button(action: {
                    showingLanguageSelector.toggle()
                }) {
                    HStack {
                        Text(viewModel.selectedLanguage)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(30)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // 聊天消息
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // 消息输入
            HStack(spacing: 10) {
                ZStack(alignment: .leading) {
                    if viewModel.newMessage.isEmpty {
                        Text("输入您的信息...")
                            .foregroundColor(.gray)
                            .padding(.leading, 20)
                    }
                    
                    TextField("", text: $viewModel.newMessage)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .background(Color.gray.opacity(0.15))
                .cornerRadius(30)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(90))
                        )
                }
                .disabled(viewModel.newMessage.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showingLanguageSelector) {
            ActionSheet(
                title: Text("选择语言"),
                buttons: [
                    .default(Text("汉语")) { viewModel.selectedLanguage = "汉语" },
                    .default(Text("English")) { viewModel.selectedLanguage = "English" },
                    .default(Text("日本語")) { viewModel.selectedLanguage = "日本語" },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingSidebar) {
            SideMenuView(showingSidebar: $showingSidebar)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - 聊天气泡视图

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser {
                Spacer()
            } else {
                // AI 头像
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.white)
                    )
                    .padding(.bottom, 5)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                if message.isLoading {
                    ProgressView()
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(16)
                } else {
                    Text(message.content)
                        .padding(12)
                        .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(message.isUser ? .white : .black)
                        .cornerRadius(16)
                }
                
                if !message.isLoading {
                    HStack(spacing: 15) {
                        if !message.isUser {
                            Button(action: {}) {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {
                                UIPasteboard.general.string = message.content
                            }) {
                                Image(systemName: "doc.on.clip")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Button(action: {
                                UIPasteboard.general.string = message.content
                            }) {
                                Image(systemName: "doc.on.clip")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if !message.isUser {
                Spacer()
            } else {
                // 用户头像
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                    .padding(.bottom, 5)
            }
        }
    }
}

// MARK: - 侧边栏视图

struct SideMenuView: View {
    @Binding var showingSidebar: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "bubble.left.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("人工智能聊天机器人")
                        .font(.headline)
                    Text("供电 DeepSeek")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 20)
            
            Button(action: {
                withAnimation {
                    showingSidebar = false
                }
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("聊天机器人")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("恢复")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "star")
                        Text("评价我们")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "headphones")
                        Text("客服支持")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // 专业版升级卡片
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "diamond.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("升级到专业版")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("解锁无限聊天功能。")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 140)
        }
        .padding()
        .frame(width: 260)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = "YOUR_API_KEY"
    @AppStorage("baseURL") private var baseURL: String = "https://openrouter.ai/api/v1/chat/completions"
    @AppStorage("model") private var model_name: String = "deepseek/deepseek-r1:free"
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Configuration")) {
                    TextField("Base URL", text: $baseURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Model", text: $model_name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(footer: Text("These settings are required to connect to the DeepSeek API.")) {
                    Button("Reset to Default") {
                        baseURL = "https://openrouter.ai/api/v1/chat/completions"
                        apiKey = "YOUR_API_KEY"
                        model_name = "deepseek/deepseek-r1:free"
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - 预览

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
