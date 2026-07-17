import Foundation
import Combine
import CryptoKit
import MongoSwift
import SwiftBSON

var currentUserID = ""
var currentUsername = ""

@MainActor
final class MessagingService: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var errorMessage = ""

    private var otherUserPublicKeys: [String: Data] = [:]
    private var refreshTask: Task<Void, Never>?
    private var activeConvoID: String?

    private func otherUserID(in convo: Conversation) -> String? {
        convo.users.first { $0 != currentUserID }
    }

    private func sharedKey(for convo: Conversation) async -> SymmetricKey? {
        guard let privateKey = CryptoManager.loadPrivateKey(forUser: currentUserID) else {
            errorMessage = "Missing encryption key on this device"
            return nil
        }

        guard let otherID = otherUserID(in: convo) else {
            return nil
        }

        if let cached = otherUserPublicKeys[otherID] {
            return CryptoManager.sharedKey(privateKey: privateKey, publicKeyData: cached)
        }

        do {
            guard let otherUser = try await getUser(id: otherID),
                  let publicKeyData = Data(base64Encoded: otherUser.publicKey) else {
                return nil
            }
            otherUserPublicKeys[otherID] = publicKeyData
            return CryptoManager.sharedKey(privateKey: privateKey, publicKeyData: publicKeyData)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func loadConversations() async {
        do {
            conversations = try await getUserConversations(userID: currentUserID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessages(convoID: String) async {
        guard let convo = conversations.first(where: { $0.convoID == convoID }) else {
            return
        }

        guard let key = await sharedKey(for: convo) else {
            return
        }

        do {
            let result = try await getMessages(convoID: convoID)
            let decrypted = result.map { msg -> Message in
                let plainText = CryptoManager.decrypt(base64: msg.message, key: key) ?? "[Unable to decrypt]"
                return Message(
                    id: msg.id,
                    sender: msg.sender,
                    convoID: msg.convoID,
                    message: plainText,
                    date: msg.date
                )
            }
            let sorted = decrypted.sorted { $0.date < $1.date }
            if sorted.map({ $0.id }) != messages.map({ $0.id }) || sorted.map({ $0.message }) != messages.map({ $0.message }) {
                messages = sorted
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startConversation(withUsername username: String) async {
        do {
            guard let otherUser = try await getUserByUsername(username) else {
                errorMessage = "No user found with that username"
                return
            }

            guard otherUser.id != currentUserID else {
                errorMessage = "You cannot message yourself"
                return
            }

            let existing = conversations.first { convo in
                convo.users.contains(otherUser.id) && convo.users.contains(currentUserID)
            }

            if let existing = existing {
                await loadMessages(convoID: existing.convoID)
                return
            }

            let newConvoID = UUID().uuidString

            let conversation = Conversation(
                id: UUID().uuidString,
                users: [currentUserID, otherUser.id],
                convoName: otherUser.username,
                convoID: newConvoID,
                convoPic: otherUser.pfp
            )

            try await createConversation(conversation)
            await loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send(text: String, convoID: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        guard let convo = conversations.first(where: { $0.convoID == convoID }) else {
            return
        }

        guard let key = await sharedKey(for: convo) else {
            return
        }

        guard let encrypted = CryptoManager.encrypt(text: text, key: key) else {
            errorMessage = "Failed to encrypt message"
            return
        }

        let message = Message(
            id: UUID().uuidString,
            sender: currentUserID,
            convoID: convoID,
            message: encrypted,
            date: Date()
        )

        do {
            try await createMessage(message)
            await loadMessages(convoID: convoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendImage(data: Data, convoID: String) async {
        guard let convo = conversations.first(where: { $0.convoID == convoID }) else {
            return
        }

        guard let key = await sharedKey(for: convo) else {
            return
        }

        do {
            let imageURL = try await CloudinaryUploader.uploadImage(data: data)

            guard let encrypted = CryptoManager.encrypt(text: "img:\(imageURL)", key: key) else {
                errorMessage = "Failed to encrypt message"
                return
            }

            let message = Message(
                id: UUID().uuidString,
                sender: currentUserID,
                convoID: convoID,
                message: encrypted,
                date: Date()
            )

            try await createMessage(message)
            await loadMessages(convoID: convoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func edit(messageID: String, newText: String, convoID: String) async {
        guard let convo = conversations.first(where: { $0.convoID == convoID }) else {
            return
        }

        guard let key = await sharedKey(for: convo) else {
            return
        }

        guard let encrypted = CryptoManager.encrypt(text: newText, key: key) else {
            errorMessage = "Failed to encrypt message"
            return
        }

        do {
            try await editMessage(
                id: messageID,
                property: "message",
                value: BSON.string(encrypted)
            )
            await loadMessages(convoID: convoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(messageID: String, convoID: String) async {
        do {
            try await deleteMessage(id: messageID)
            await loadMessages(convoID: convoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(conversationID: String) async {
        do {
            try await deleteConversation(id: conversationID)
            await loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setActiveConvo(_ convoID: String?) {
        activeConvoID = convoID
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                await self.loadConversations()
                if let convoID = self.activeConvoID {
                    await self.loadMessages(convoID: convoID)
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
