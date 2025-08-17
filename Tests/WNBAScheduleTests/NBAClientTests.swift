import XCTest
@testable import WNBASchedule

// Import the URLSessionProtocol from NBAClient
// This is already imported via @testable import WNBASchedule

final class NBAClientTests: XCTestCase {
    // MARK: - Properties
    
    private var mockCache: MockAPICache?
    private var mockURLSession: MockURLSession?
    private var client: NBAClient?
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockCache = MockAPICache()
        mockURLSession = MockURLSession()
        if let mockURLSession = mockURLSession, let mockCache = mockCache {
            client = NBAClient(baseURL: "https://test.api.com", session: mockURLSession, cache: mockCache)
        }
    }
    
    override func tearDown() {
        mockCache = nil
        mockURLSession = nil
        client = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testFetchScheduleFromCache() async throws {
        // Setup mock cache data
        let mockData = createMockScheduleData()
        let cacheKey = "schedule_2025"
        guard let mockCache = mockCache, let client = client else {
            XCTFail("Mocks not initialized")
            return
        }
        mockCache.mockData[cacheKey] = mockData
        
        // Execute
        let response = try await client.fetchSchedule(season: "2025")
        
        // Verify
        XCTAssertEqual(mockCache.lastRequestedKey, cacheKey)
        XCTAssertEqual(response.results.schedule.count, 1)
        XCTAssertEqual(response.results.schedule.first?.gid, "1022500001")
        
        // Verify no network request was made
        XCTAssertNil(mockURLSession?.lastRequest)
    }
    
    func testFetchScheduleFromNetwork() async throws {
        // Setup mock network response
        let mockData = createMockScheduleData()
        guard let mockURLSession = mockURLSession, let client = client, let mockCache = mockCache else {
            XCTFail("Mocks not initialized")
            return
        }
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.api.com") ?? URL(fileURLWithPath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Execute
        let response = try await client.fetchSchedule(season: "2025")
        
        // Verify
        XCTAssertNotNil(mockURLSession.lastRequest)
        XCTAssertEqual(response.results.schedule.count, 1)
        XCTAssertEqual(response.results.schedule.first?.gid, "1022500001")
        
        // Verify data was cached
        XCTAssertEqual(mockCache.lastStoredKey, "schedule_2025")
        XCTAssertEqual(mockCache.lastStoredData, mockData)
    }
    
    func testFetchScheduleWithCurrentYear() async throws {
        // Setup mock network response
        let mockData = createMockScheduleData()
        guard let mockURLSession = mockURLSession, let client = client, let mockCache = mockCache else {
            XCTFail("Mocks not initialized")
            return
        }
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.api.com") ?? URL(fileURLWithPath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Execute with nil season (should use current year)
        let response = try await client.fetchSchedule(season: nil)
        
        // Verify
        XCTAssertNotNil(mockURLSession.lastRequest)
        XCTAssertEqual(response.results.schedule.count, 1)
        XCTAssertEqual(response.results.schedule.first?.gid, "1022500001")
        
        // Verify data was cached with current year
        let currentYear = String(Calendar.current.component(.year, from: Date()))
        XCTAssertEqual(mockCache.lastStoredKey, "schedule_\(currentYear)")
        XCTAssertEqual(mockCache.lastStoredData, mockData)
    }
    
    func testFetchScheduleWithNetworkError() async {
        // Setup mock network error
        guard let mockURLSession = mockURLSession, let client = client else {
            XCTFail("Mocks not initialized")
            return
        }
        mockURLSession.mockError = NSError(
            domain: "test",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Network error"]
        )
        
        // Execute and verify
        do {
            _ = try await client.fetchSchedule(season: "2025")
            XCTFail("Expected error but got success")
        } catch let error as NBAClientError {
            if case .networkError(let underlyingError) = error {
                XCTAssertEqual((underlyingError as NSError).domain, "test")
                XCTAssertEqual((underlyingError as NSError).code, -1)
            } else {
                XCTFail("Expected networkError but got \(error)")
            }
        } catch {
            XCTFail("Expected NBAClientError but got \(error)")
        }
    }
    
    func testFetchScheduleWithInvalidResponse() async {
        // Setup mock invalid response
        guard let mockURLSession = mockURLSession, let client = client else {
            XCTFail("Mocks not initialized")
            return
        }
        mockURLSession.mockData = createMockScheduleData()
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.api.com") ?? URL(fileURLWithPath: "/"),
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Execute and verify
        do {
            _ = try await client.fetchSchedule(season: "2025")
            XCTFail("Expected error but got success")
        } catch let error as NBAClientError {
            if case .invalidResponse(let statusCode) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected invalidResponse but got \(error)")
            }
        } catch {
            XCTFail("Expected NBAClientError but got \(error)")
        }
    }
    
    func testFetchScheduleWithDecodingError() async {
        // Setup mock invalid data
        guard let mockURLSession = mockURLSession, let client = client else {
            XCTFail("Mocks not initialized")
            return
        }
        let invalidData = Data("invalid json".utf8)
        mockURLSession.mockData = invalidData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://test.api.com") ?? URL(fileURLWithPath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Execute and verify
        do {
            _ = try await client.fetchSchedule(season: "2025")
            XCTFail("Expected error but got success")
        } catch let error as NBAClientError {
            if case .decodingError = error {
                // Success
            } else {
                XCTFail("Expected decodingError but got \(error)")
            }
        } catch {
            XCTFail("Expected NBAClientError but got \(error)")
        }
    }
    
    func testFetchScheduleWithServerError() async {
        // Setup mock server error
        mockURLSession?.mockData = createMockScheduleData()
        if let url = URL(string: "https://test.api.com") {
            mockURLSession?.mockResponse = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )
        } else {
            XCTFail("Invalid URL string for mock response")
        }
        
        // Execute and verify
        do {
            _ = try await client?.fetchSchedule(season: "2025")
            XCTFail("Expected error but got success")
        } catch let error as NBAClientError {
            if case .serverError = error {
                // Success
            } else {
                XCTFail("Expected serverError but got \(error)")
            }
        } catch {
            XCTFail("Expected NBAClientError but got \(error)")
        }
    }
    
    func testFetchScheduleWithRateLimitedError() async {
        // Setup mock rate limited response
        mockURLSession?.mockData = createMockScheduleData()
        if let url = URL(string: "https://test.api.com") {
            mockURLSession?.mockResponse = HTTPURLResponse(
                url: url,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )
        } else {
            XCTFail("Invalid URL string for mock response")
        }
        
        // Execute and verify
        do {
            _ = try await client?.fetchSchedule(season: "2025")
            XCTFail("Expected error but got success")
        } catch let error as NBAClientError {
            if case .rateLimited = error {
                // Success
            } else {
                XCTFail("Expected rateLimited but got \(error)")
            }
        } catch {
            XCTFail("Expected NBAClientError but got \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockScheduleData() -> Data {
        let json = """
        {
            "results": {
                "schedule": [
                    {
                        "id": 1,
                        "gid": "1022500001",
                        "type": "game",
                        "title": "Test Game",
                        "easternTime": "2025-05-01T19:00:00Z",
                        "homeTime": "2025-05-01T19:00:00Z",
                        "visitorTime": "2025-05-01T19:00:00Z",
                        "utcTime": "2025-05-01T23:00:00Z",
                        "timestamp": 1746226800000,
                        "home": {
                            "tid": 1,
                            "abbr": "NYL",
                            "city": "New York",
                            "name": "Liberty",
                            "score": 85,
                            "losses": 2,
                            "wins": 10
                        },
                        "visitor": {
                            "tid": 2,
                            "abbr": "LVA",
                            "city": "Las Vegas",
                            "name": "Aces",
                            "score": 80,
                            "losses": 3,
                            "wins": 9
                        },
                        "state": 3,
                        "arenaName": "Barclays Center",
                        "arenaState": "NY",
                        "arenaCity": "Brooklyn"
                    }
                ]
            }
        }
        """
        guard let data = json.data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to Data")
            return Data()
        }
        return data
    }
}

// MARK: - Mock Classes

class MockAPICache: APICacheProtocol {
    var mockData: [String: Data] = [:]
    var lastRequestedKey: String?
    var lastStoredKey: String?
    var lastStoredData: Data?
    var lastStoredExpirationInterval: TimeInterval?
    
    func getData(for key: String) -> Data? {
        lastRequestedKey = key
        return mockData[key]
    }
    
    func storeData(_ data: Data, for key: String, expirationInterval: TimeInterval) {
        lastStoredKey = key
        lastStoredData = data
        lastStoredExpirationInterval = expirationInterval
        mockData[key] = data
    }
    
    func clearCache() {
        mockData.removeAll()
    }
}

// Create a mock implementation of the protocol
class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?
    
    // Initialize with default values
    init(mockData: Data? = nil, mockResponse: URLResponse? = nil, mockError: Error? = nil) {
        self.mockData = mockData
        self.mockResponse = mockResponse
        self.mockError = mockError
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data or response"])
        }
        
        return (data, response)
    }
}

// End of NBAClientTests
