import Foundation
import os.log

/// Protocol for URL session operations
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {}

/// Errors that can occur during API requests
enum NBAClientError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse(Int)
    case decodingError(Error)
    case cacheError(String)
    case rateLimited
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let statusCode):
            return "Invalid response with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .cacheError(let message):
            return "Cache error: \(message)"
        case .rateLimited:
            return "Rate limited by the API"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

/// Protocol for NBA API client
protocol NBAClientProtocol {
    /// Fetches the WNBA schedule for a given season
    /// - Parameter season: The season year (e.g., "2025")
    /// - Returns: The schedule response
    func fetchSchedule(season: String) async throws -> ScheduleResponse
}

/// Client for interacting with the NBA API
class NBAClient: NBAClientProtocol {
    // MARK: - Properties
    
    private let baseURL: String
    private let session: URLSessionProtocol
    private let cache: APICacheProtocol
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "NBAClient")
    
    // Cache configuration
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    // Retry configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    init(
        baseURL: String = "https://content-api-prod.nba.com/public/1/leagues/wnba/schedule",
        session: URLSessionProtocol = URLSession.shared,
        cache: APICacheProtocol
    ) {
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
        
        logger.info("NBAClient initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Public Methods
    
    func fetchSchedule(season: String = "2025") async throws -> ScheduleResponse {
        // Generate cache key
        let cacheKey = "schedule_\(season)"
        
        // Try to get from cache first
        if let cachedData = cache.getData(for: cacheKey) {
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ScheduleResponse.self, from: cachedData)
                logger.info("Retrieved schedule from cache for season \(season)")
                return response
            } catch {
                logger.error("Failed to decode cached schedule: \(error.localizedDescription)")
                // Continue to fetch fresh data if cache decoding fails
            }
        }
        
        // Build the URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw NBAClientError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "addEvents", value: "true"),
            URLQueryItem(name: "seasonYear", value: season)
        ]
        
        guard let url = urlComponents.url else {
            throw NBAClientError.invalidURL
        }
        
        // Fetch with retry logic
        return try await fetchWithRetry(url: url, cacheKey: cacheKey, retryCount: 0)
    }
    
    // MARK: - Private Methods
    
    private func fetchWithRetry(url: URL, cacheKey: String, retryCount: Int) async throws -> ScheduleResponse {
        do {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            
            logger.info("Fetching schedule from URL: \(url.absoluteString)")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NBAClientError.invalidResponse(0)
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    let decoder = JSONDecoder()
                    let scheduleResponse = try decoder.decode(ScheduleResponse.self, from: data)
                    
                    // Cache the successful response
                    cache.storeData(data, for: cacheKey, expirationInterval: cacheExpirationInterval)
                    
                    logger.info("Successfully fetched and cached schedule")
                    return scheduleResponse
                } catch {
                    logger.error("Decoding error: \(error.localizedDescription)")
                    throw NBAClientError.decodingError(error)
                }
                
            case 429:
                // Rate limited
                logger.warning("Rate limited by API")
                throw NBAClientError.rateLimited
                
            case 500...599:
                // Server error
                logger.error("Server error with status code: \(httpResponse.statusCode)")
                throw NBAClientError.serverError("Server returned status code \(httpResponse.statusCode)")
                
            default:
                logger.error("Invalid response with status code: \(httpResponse.statusCode)")
                throw NBAClientError.invalidResponse(httpResponse.statusCode)
            }
            
        } catch let error as NBAClientError {
            // If we can retry, do so with exponential backoff
            if retryCount < maxRetries {
                // Calculate delay with exponential backoff
                let delay = retryDelay * pow(2.0, Double(retryCount))
                logger.info("Retrying request (attempt \(retryCount + 1) of \(self.maxRetries)) after \(delay) seconds")
                        
                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Retry the request
                return try await fetchWithRetry(url: url, cacheKey: cacheKey, retryCount: retryCount + 1)
            }
            
            // We've exhausted our retries
            throw error
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw NBAClientError.networkError(error)
        }
    }
}
