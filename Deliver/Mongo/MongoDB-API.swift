import MongoSwift
import NIOCore
import NIOPosix
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let password: String
    let salt: String
    let pfp: String
    let isAdmin: Bool
    let creationDate: Date
    let publicKey: String
}

struct Message: Codable, Identifiable {
    let id: String
    let sender: String
    let convoID: String
    let message: String
    let date: Date
}

struct Conversation: Codable, Identifiable {
    let id: String
    let users: [String]
    let convoName: String
    let convoID: String
    let convoPic: String
}

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

let database: MongoDatabase = {
    do {
        let client = try MongoClient(
            "mongodb://poopeating1234_db_user:zuRvyf-fotkoj-8jybne@ac-oh9gmfj-shard-00-00.j0vegkn.mongodb.net:27017,ac-oh9gmfj-shard-00-01.j0vegkn.mongodb.net:27017,ac-oh9gmfj-shard-00-02.j0vegkn.mongodb.net:27017/?ssl=true&replicaSet=atlas-s9kzg0-shard-0&authSource=admin&retryWrites=true&w=majority&appName=Deliver",
            using: eventLoopGroup
        )

        return client.db("Deliver")
    } catch {
        fatalError("MongoDB connection failed: \(error)")
    }
}()

let users = database.collection("users", withType: User.self)
let messages = database.collection("messages", withType: Message.self)
let conversations = database.collection("conversations", withType: Conversation.self)

func createUser(_ user: User) async throws {
    try await users.insertOne(user)
}

func deleteUser(id: String) async throws {
    try await users.deleteOne([
        "id": BSON.string(id)
    ])
}

func modifyUser(
    id: String,
    property: String,
    value: BSON
) async throws {
    try await users.updateOne(
        filter: [
            "id": BSON.string(id)
        ],
        update: [
            "$set": [
                property: value
            ]
        ]
    )
}

func getUserByUsername(_ username: String) async throws -> User? {
    let cursor = try await users.find([
        "username": BSON.string(username)
    ])

    for try await user in cursor {
        return user
    }

    return nil
}

func getUser(id: String) async throws -> User? {
    let cursor = try await users.find([
        "id": BSON.string(id)
    ])

    for try await user in cursor {
        return user
    }

    return nil
}

func createConversation(_ conversation: Conversation) async throws {
    try await conversations.insertOne(conversation)
}

func deleteConversation(id: String) async throws {
    try await conversations.deleteOne([
        "id": BSON.string(id)
    ])
}

func editConversation(
    id: String,
    property: String,
    value: BSON
) async throws {
    try await conversations.updateOne(
        filter: [
            "id": BSON.string(id)
        ],
        update: [
            "$set": [
                property: value
            ]
        ]
    )
}

func getUserConversations(userID: String) async throws -> [Conversation] {
    let cursor = try await conversations.find([
        "users": BSON.string(userID)
    ])

    var result: [Conversation] = []

    for try await conversation in cursor {
        result.append(conversation)
    }

    return result
}

func createMessage(_ message: Message) async throws {
    try await messages.insertOne(message)
}

func editMessage(
    id: String,
    property: String,
    value: BSON
) async throws {
    try await messages.updateOne(
        filter: [
            "id": BSON.string(id)
        ],
        update: [
            "$set": [
                property: value
            ]
        ]
    )
}

func deleteMessage(id: String) async throws {
    try await messages.deleteOne([
        "id": BSON.string(id)
    ])
}

func getMessages(convoID: String) async throws -> [Message] {
    let cursor = try await messages.find([
        "convoID": BSON.string(convoID)
    ])

    var result: [Message] = []

    for try await message in cursor {
        result.append(message)
    }

    return result
}

func getConversations(convoID: String) async throws -> [Conversation] {
    let cursor = try await conversations.find([
        "convoID": BSON.string(convoID)
    ])

    var result: [Conversation] = []

    for try await conversation in cursor {
        result.append(conversation)
    }

    return result
}
