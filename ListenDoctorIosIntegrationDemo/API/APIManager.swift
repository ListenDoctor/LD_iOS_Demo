//
//  APIManager.swift
//  ListenDoctorIosIntegrationDemo
//

import Foundation
import UniformTypeIdentifiers

// MARK: - API Manager for handling requests
@Observable
class APIManager: ObservableObject {
    
    let baseURL = URL(string: "https://api-beta.listen.doctor/")!
    private let versionUrl = "v1"
    private var apiKey: String
    private(set) var token: String?
    private var urlSession: URLSession
    
    init(apiKey: String, sessionConfiguration: URLSessionConfiguration = .default) {
        self.apiKey = apiKey
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 30
        sessionConfiguration.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: sessionConfiguration)
    }
    
    func getToken() -> String? {
        return token
    }
    
    // MARK: - Public Methods
    
    /**
     * Authenticate with the API using the provided credentials. The token for this session is stored in the `token` property.
     * - Parameter clientId: The client ID for the application.
     * - Parameter clientSecret: The client secret for the application.
     * - Parameter doctorId: The doctor ID for the user.
     * - Throws: An error if the request fails
     * - Returns: Void
     */
    func authenticate(clientId: String, clientSecret: String, doctorId: String) async throws {
        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "client_credentials",
            "doctor": doctorId
        ]
        let request = try createRequest(endpoint: "iam", method: .post, body: body)
        
        let (data, response) = try await urlSession.data(for: request)
        let responseData: IAMResponse = try handleResponse(data, response: response)
        Task { @MainActor in
            
            self.token = responseData.token
        }
    }
    
    /**
     * Get the public templates available in the API.
     * - Throws: An error if the request fails
     * - note: Requires authentication
     */
    func getPublicTemplates() async throws -> [String : [Template]] {
        let request = try createRequest(endpoint: "templates/public", method: .get, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Get the custom templates of the authenticated user.
     * - Throws: An error if the request fails
     * - note: Requires authentication
     */
    func getUserTemplates() async throws -> [String : [Template]] {
        let request = try createRequest(endpoint: "templates", method: .get, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Add a new template to the user's account.
     * - Parameter name: The name of the template.
     * - Parameter template: The template content.
     * - Parameter speciality: The speciality code for the template.
     * - Parameter category: The category of the template.
     * - Throws: An error if the request fails
     * - Returns: A `TemplateResponse` object with the response data
     * - note: Requires authentication
     */
    func addTemplate(name: String, template: String, speciality: Int, category: String) async throws -> TemplateResponse {
        let body: [String: Any] = [
            "name": name,
            "template": template,
            "speciality": speciality,
            "category": category
        ]
        let request = try createRequest(endpoint: "templates", method: .post, withToken: true, body: body)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Update an existing template in the user's account.
     * - Parameter guid: The GUID of the template to update.
     * - Parameter name: The new name of the template.
     * - Parameter template: The new template content.
     * - Parameter speciality: The new speciality code for the template.
     * - Parameter category: The new category of the template.
     * - Throws: An error if the request fails
     * - Returns: A `TemplateResponse` object with the response data
     * - note: Requires authentication
     */
    func updateTemplate(guid: String, name: String, template: String, speciality: Int, category: String) async throws -> TemplateResponse {
        let body: [String: Any] = [
            "guid": guid,
            "name": name,
            "template": template,
            "speciality": speciality,
            "category": category
        ]
        let request = try createRequest(endpoint: "templates", method: .put, withToken: true, body: body)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Get a specific template by GUID. This can be a public or user template.
     * - Parameter guid: The GUID of the template to retrieve.
     * - Throws: An error if the request fails
     * - Returns: A `Template` object with the template data
     * - note: Requires authentication
     */
    func getTemplate(byGUID guid: String) async throws -> Template {
        let request = try createRequest(endpoint: "templates/\(guid)", method: .get, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Delete a template from the user's account.
     * - Parameter guid: The GUID of the template to delete.
     * - Throws: An error if the request fails
     * - Returns: A `TemplateDeletedResponse` object with the response data
     * - note: Requires authentication
     */
    func deleteTemplate(byGUID guid: String) async throws -> TemplateDeletedResponse {
        let request = try createRequest(endpoint: "templates/\(guid)", method: .delete, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Get the list of specialities available in the API.
     * - Throws: An error if the request fails
     * - Returns: A dictionary of specialities with the language codes as keys
     * - note: Requires authentication
     */
    func getSpecialities() async throws -> [String : [Speciality]] {
        let request = try createRequest(endpoint: "specialities", method: .get, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Get a specific speciality by code.
     * - Parameter code: The code of the speciality to retrieve.
     * - Throws: An error if the request fails
     * - Returns: A `Speciality` object with the speciality data
     * - note: Requires authentication
     */
    func getSpeciality(byCode code: Int) async throws -> Speciality {
        let request = try createRequest(endpoint: "specialities/\(code)", method: .get, withToken: true)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Process an audio file to generate a summary and transcription. The file must be in a supported format. The response includes the summary and transcription text.
     * - Parameter fileURL: The URL of the audio file to process.
     * - Parameter prompt: The prompt for the transcription.
     * - Parameter language: The language of the audio file.
     * - Parameter speciality: The speciality code for the transcription.
     * - Parameter category: The category of the transcription.
     * - Parameter datetime: The datetime of the transcription. Format: "yyyy-MM-dd HH:mm:ss"
     * - Throws: An error if the request fails
     * - Returns: A `SummaryTranscriptionResponse` object with the response data
     * - note: Requires authentication
     * - warning: The audio file must be in a supported format. The API currently supports wav, ogg, m4a, mp3, or mp4 formats.
     * - warning: The audio file must be less than 50MB in size
     * - warning: The audio must be in a single channel (mono) format and 8 bit depth
     */
    func processAudio(
        fileURL: URL,
        prompt: String,
        language: String,
        speciality: Int,
        category: String,
        datetime: String
    ) async throws -> SummaryTranscriptionResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // Create URLRequest
        var request = URLRequest(url: URL(string: "https://api-beta.listen.doctor/v1/process/audio")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: HTTPHeader.apiKey.rawValue)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: HTTPHeader.contentType.rawValue)
        
        let params =  [
            "prompt": prompt,
            "language": language,
            "speciality": String(speciality),
            "category": category,
            "datetime": datetime
        ]
        // Prepare the multipart body data
        let bodyData = try createMultipartBody(
            fileURL: fileURL,
            parameters: params,
            boundary: boundary
        )
        
        // Upload the data
        let (data, response) = try await urlSession.upload(for: request, from: bodyData)
        
        // Ensure valid response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
        }
        guard httpResponse.statusCode == 200 else {
            
            let log =
            "Params: \(params)\nToken:\(String(describing: token))\nApiKey:\(apiKey)\nFile:\(fileURL.lastPathComponent)\n\nMethod: \("POST")\nResponse:\(httpResponse.description)"
            throw NSError(domain: log, code: -1, userInfo: nil)
        }
        
        // Decode the response
        return try JSONDecoder().decode(SummaryTranscriptionResponse.self, from: data)
    }
    
    /**
     * Create a multipart form data body for a file upload.
     */
    private func createMultipartBody(fileURL: URL, parameters: [String: String], boundary: String) throws -> Data {
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add the file data
        let filename = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(FileHelper.mimeType(for: fileURL) ?? "" )\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    /**
     * Given a transcription text, reprocess it to generate a new summary.
     * - Parameter data: The transcription text to reprocess.
     * - Parameter prompt: The prompt for the transcription.
     * - Parameter language: The language of the transcription.
     * - Parameter speciality: The speciality code for the transcription.
     * - Parameter datetime: The datetime of the transcription. Format: "yyyy-MM-dd HH:mm:ss"
     * - Throws: An error if the request fails
     * - Returns: A `SummaryResponse` object with the response data
     * - note: Requires authentication
     */
    func reprocessTranscription(data: String, prompt: String, language: String, speciality: Int, datetime: String) async throws -> SummaryResponse {
        let body: [String: Any] = [
            "data": data,
            "prompt": prompt,
            "language": language,
            "speciality": speciality,
            "datetime": datetime
        ]
        let request = try createRequest(endpoint: "process/again", method: .post, withToken: true, body: body)
        
        let (data, response) = try await urlSession.data(for: request)
        return try handleResponse(data, response: response)
    }
    
    /**
     * Given a lab / test / health document file, summarize its content.
     * - Parameter fileURL: The URL of the document file to summarize.
     * - Parameter language: The language of the document.
     * - Throws: An error if the request fails
     * - Returns: A `SummaryResponse` object with the response data
     * - note: Requires authentication
     */
    func summarizeDocument(fileURL: URL, language: String) async throws -> SummaryResponse {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api-beta.listen.doctor/v1/process/laboratory")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: HTTPHeader.apiKey.rawValue)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: HTTPHeader.contentType.rawValue)
        
        let params =  [
            "language": language,
            "file": fileURL.lastPathComponent
        ]
        // Prepare the multipart body data
        let bodyData = try createMultipartBody(
            fileURL: fileURL,
            parameters: params,
            boundary: boundary
        )
        
        // Upload the data
        let (data, response) = try await urlSession.upload(for: request, from: bodyData)
        
        // Ensure valid response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
        }
        guard httpResponse.statusCode == 200 else {
            
            let log =
            "Params: \(params)\nToken:\(String(describing: token))\nApiKey:\(apiKey)\nFile:\(fileURL.lastPathComponent)\n\nMethod: \("POST")\nResponse:\(httpResponse.description)"
            throw NSError(domain: log, code: -1, userInfo: nil)
        }
        
        // Decode the response
        return try JSONDecoder().decode(SummaryResponse.self, from: data)
    }
}

// MARK: - APIManager Extensions for Abstractions
extension APIManager {
    
    private func createRequest(endpoint: String, method: HTTPMethod, withToken: Bool = false, body: [String: Any]? = nil) throws -> URLRequest {
        
        let endpointComponents = endpoint.components(separatedBy: "/")
        var url = baseURL.appending(component: versionUrl)
        endpointComponents.forEach { url.append(component: $0) }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        if withToken, let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }
    
    private func handleResponse<T: Decodable>(_ data: Data, response: URLResponse) throws -> T {
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Data Extension for Multipart Form Encoding
private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Supporting Types
struct IAMResponse: Decodable {
    let token: String
}

struct TemplateResponse: Decodable {
    let msg: String
    let guid: String
}

struct TemplateDeletedResponse: Decodable {
    let msg: String
}

struct SummaryTranscriptionResponse: Decodable {
    let summary: String
    let transcription: String
}

struct SummaryResponse: Decodable {
    let summary: String
}

// MARK: - Enums for Constants
private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

private enum HTTPHeader: String {
    case apiKey = "x-api-key"
    case authorization = "Authorization"
    case contentType = "Content-Type"
}

private enum ContentType: String {
    case json = "application/json"
    case multipartFormData = "multipart/form-data"
}

// Helper to add data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
