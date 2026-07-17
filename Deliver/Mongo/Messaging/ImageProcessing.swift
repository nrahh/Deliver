import Foundation

struct CloudinaryUploader {
    static let cloudName = "qpcmscol"
    static let uploadPreset = "deliver_unsigned"

    static func uploadImage(data: Data) async throws -> String {
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (respData, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Cloudinary", code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
              let secureUrl = json["secure_url"] as? String else {
            throw NSError(domain: "Cloudinary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad response"])
        }

        return secureUrl
    }

    static func downloadImage(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Cloudinary", code: 2, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
        }
        return data
    }
}
