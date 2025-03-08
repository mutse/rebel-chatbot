//
//  ContentView.swift
//  rebel
//
//  Created by Mutse Yang on 8/3/25.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(content: "Hello! How can I assist you today?", isUser: false, timestamp: Date().addingTimeInterval(-300)),
        ChatMessage(content: "介绍下自己", isUser: true, timestamp: Date().addingTimeInterval(-240)),
        ChatMessage(content: "我是DeepSeek，一款由R1开发的人工智能，旨在帮助用户理解字宙并回答各种问题。我的设计灵感来源于《银河系漫游指南》和《钢铁侠》中的JARVIS，致力于提供有帮助且真实的回答，通常还会带有一点对人类的外部视角。我在这里帮助你探索，学习，并在你的旅程中提供协助！", isUser: false, timestamp: Date().addingTimeInterval(-180)),
        ChatMessage(content: "一个汉字具有左右结构，左边是木，右边是艺，只需回答这是什么字即可。", isUser: true, timestamp: Date().addingTimeInterval(-120)),
        ChatMessage(content: "", isUser: false, timestamp: Date().addingTimeInterval(-60))
    ]
    
    @State private var newMessage: String = ""
    @State private var showingLanguageSelector = false
    @State private var selectedLanguage = "中国人"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Deep AI Chatbot")
                        .font(.headline)
                        .padding()
                    Spacer()
                    
                    Button(action: {
                        // New chat action
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    
                    Button(action: {
                        // Export action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    
                    Button(action: {
                        // History action
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal)
                .frame(height: 50)
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Language selector
                HStack(spacing: 10) {
                    Text("R1")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    Button(action: {
                        showingLanguageSelector.toggle()
                    }) {
                        HStack {
                            Text(selectedLanguage)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Message input
                HStack(spacing: 10) {
                    TextField("输入您的信息...", text: $newMessage)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(24)
                    
                    Button(action: {
                        if !newMessage.isEmpty {
                            let userMessage = ChatMessage(content: newMessage, isUser: true, timestamp: Date())
                            messages.append(userMessage)
                            newMessage = ""
                            
                            // Simulate AI response
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                let aiResponse = ChatMessage(content: "这是AI的回复示例。", isUser: false, timestamp: Date())
                                messages.append(aiResponse)
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .actionSheet(isPresented: $showingLanguageSelector) {
                ActionSheet(
                    title: Text("选择语言"),
                    buttons: [
                        .default(Text("中国人")) { selectedLanguage = "中国人" },
                        .default(Text("English")) { selectedLanguage = "English" },
                        .default(Text("日本語")) { selectedLanguage = "日本語" },
                        .cancel()
                    ]
                )
            }
        }
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            } else {
                CircleAvatar(isUser: message.isUser)
                    .padding(.trailing, 8)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                HStack(spacing: 8) {
                    if !message.isUser {
                        Button(action: {}) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            } else {
                CircleAvatar(isUser: message.isUser)
                    .padding(.leading, 8)
            }
        }
    }
}

struct CircleAvatar: View {
    let isUser: Bool
    
    var body: some View {
        Circle()
            .fill(isUser ? Color.gray.opacity(0.3) : Color.blue)
            .frame(width: 36, height: 36)
            .overlay(
                Group {
                    if isUser {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.white)
                    }
                }
            )
    }
}

struct SideMenuView: View {
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
            
            Button(action: {}) {
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
                        Text("评价我们")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Pro upgrade card
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

#Preview {
    ContentView()
}
