import Foundation

enum NBAClientError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

class NBAClient {
    private let baseURL = "https://content-api-prod.nba.com/public/1/leagues/wnba/schedule"
    private let session = URLSession.shared
    
    func fetchSchedule(season: String = "2025") async throws -> ScheduleResponse {
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
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode) else {
                throw NBAClientError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(ScheduleResponse.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NBAClientError.decodingError(error)
            }
        } catch let error as NBAClientError {
            throw error
        } catch {
            throw NBAClientError.networkError(error)
        }
    }
}