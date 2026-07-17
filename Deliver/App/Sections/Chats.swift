import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct Chats: View {
    @StateObject private var service = MessagingService()
    @State private var selectedConvoID: String?
    @State private var showAddAlert = false
    @State private var newUsername = ""
    @State private var messageText = ""
    @State private var editingMessageID: String?
    @State private var editingText = ""
    @State private var isUploadingImage = false

    private var selectedConvo: Conversation? {
        service.conversations.first { $0.convoID == selectedConvoID }
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Chats")
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button {
                        showAddAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(service.conversations) { convo in
                            HStack {
                                Text(convo.convoName)
                                    .font(.system(size: 16, weight: .regular))

                                Spacer()

                                Button {
                                    Task {
                                        await service.remove(conversationID: convo.id)
                                        if selectedConvoID == convo.convoID {
                                            selectedConvoID = nil
                                        }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(selectedConvoID == convo.convoID ? 0.08 : 0.02))
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedConvoID = convo.convoID
                                Task {
                                    await service.loadMessages(convoID: convo.convoID)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: 200)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 10) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(service.messages) { message in
                            VStack(alignment: message.sender == currentUserID ? .trailing : .leading, spacing: 4) {
                                if editingMessageID == message.id {
                                    HStack {
                                        TextField("Edit message", text: $editingText)
                                            .textFieldStyle(.roundedBorder)

                                        Button("Save") {
                                            Task {
                                                await service.edit(
                                                    messageID: message.id,
                                                    newText: editingText,
                                                    convoID: message.convoID
                                                )
                                                editingMessageID = nil
                                            }
                                        }

                                        Button("Cancel") {
                                            editingMessageID = nil
                                        }
                                    }
                                } else {
                                    HStack {
                                        if message.message.hasPrefix("img:"),
                                           let url = URL(string: String(message.message.dropFirst(4))) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: 220, maxHeight: 220)
                                                        .cornerRadius(10)
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .frame(width: 100, height: 100)
                                                default:
                                                    ProgressView()
                                                        .frame(width: 100, height: 100)
                                                }
                                            }
                                        } else {
                                            Text(message.message)
                                                .padding(10)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(10)
                                        }

                                        if message.sender == currentUserID {
                                            if !message.message.hasPrefix("img:") {
                                                Button {
                                                    editingMessageID = message.id
                                                    editingText = message.message
                                                } label: {
                                                    Image(systemName: "pencil")
                                                }
                                                .buttonStyle(.plain)
                                            }

                                            Button {
                                                Task {
                                                    await service.delete(
                                                        messageID: message.id,
                                                        convoID: message.convoID
                                                    )
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    Text(formatted(message.date, sender: message.sender))
                                        .font(.system(size: 11))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: message.sender == currentUserID ? .trailing : .leading)
                        }
                    }
                }

                if let convoID = selectedConvoID {
                    HStack {
                        Button {
                            pickImage(convoID: convoID)
                        } label: {
                            if isUploadingImage {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isUploadingImage)

                        TextField("Message...", text: $messageText)
                            .textFieldStyle(.roundedBorder)

                        Button("Send") {
                            let text = messageText
                            messageText = ""
                            Task {
                                await service.send(text: text, convoID: convoID)
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .frame(maxWidth: 400)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
        }
        .padding(10)
        .frame(width: 800, height: 600, alignment: .topLeading)
        .task {
            await service.loadConversations()
        }
        .alert("Add Conversation", isPresented: $showAddAlert) {
            TextField("Username", text: $newUsername)

            Button("Add") {
                let username = newUsername
                newUsername = ""
                Task {
                    await service.startConversation(withUsername: username)
                }
            }

            Button("Cancel", role: .cancel) {
                newUsername = ""
            }
        }
        .alert("Error", isPresented: Binding(
            get: { !service.errorMessage.isEmpty },
            set: { _ in service.errorMessage = "" }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(service.errorMessage)
        }
    }

    private func pickImage(convoID: String) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url) else {
            return
        }

        isUploadingImage = true
        Task {
            await service.sendImage(data: data, convoID: convoID)
            isUploadingImage = false
        }
    }

    private func formatted(_ date: Date, sender: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let name = sender == currentUserID ? "You" : (selectedConvo?.convoName ?? "User")
        return "\(name) · \(formatter.string(from: date))"
    }
}

#Preview {
    ContentView()
}
