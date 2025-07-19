import Foundation
import os.log
import CommonCrypto

/// Protocol for API caching functionality
protocol APICacheProtocol {
    /// Retrieves cached data for a given key if available and not expired
    /// - Parameter key: The cache key
    /// - Returns: Cached data if available and valid, nil otherwise
    func getData(for key: String) -> Data?
    
    /// Stores data in the cache with a given key
    /// - Parameters:
    ///   - data: The data to cache
    ///   - key: The cache key
    ///   - expirationInterval: Time interval after which the cache expires (default: 1 hour)
    func storeData(_ data: Data, for key: String, expirationInterval: TimeInterval)
    
    /// Clears all cached data
    func clearCache()
    
    /// Removes expired cache entries
    func removeExpiredEntries()
}

/// A simple in-memory and disk cache for API responses
class APICache: APICacheProtocol {
    // MARK: - Properties
    
    /// In-memory cache for faster access
    private var memoryCache: [String: CacheEntry] = [:]
    
    /// Cache entry expiration time (default: 1 hour)
    private let defaultExpirationInterval: TimeInterval = 3600
    
    /// Maximum memory cache size in bytes (default: 10 MB)
    private let maxMemoryCacheSize: Int = 10 * 1024 * 1024
    
    /// Current memory cache size in bytes
    private var currentMemoryCacheSize: Int = 0
    
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "APICache")
    
    // MARK: - Cache Entry
    
    /// Represents a cached item with its data and expiration time
    private struct CacheEntry {
        let data: Data
        let expirationDate: Date
        
        var isExpired: Bool {
            return Date() > expirationDate
        }
        
        var sizeInBytes: Int {
            return data.count
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Create cache directory if needed
        createCacheDirectoryIfNeeded()
        
        // Clean up expired cache entries on initialization
        removeExpiredEntries()
        
        logger.info("APICache initialized")
    }
    
    // MARK: - Public Methods
    
    func getData(for key: String) -> Data? {
        // First check memory cache for faster access
        if let entry = memoryCache[key], !entry.isExpired {
            logger.debug("Cache hit (memory) for key: \(key)")
            return entry.data
        }
        
        // If not in memory, check disk cache
        let cacheFilePath = cacheFileURL(for: key).path
        
        if FileManager.default.fileExists(atPath: cacheFilePath) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: cacheFilePath)
                
                // Check if cache file has expired
                if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
                    // Read expiration interval from a custom property file
                    let metadataURL = URL(fileURLWithPath: cacheFilePath).appendingPathExtension("metadata")
                    if FileManager.default.fileExists(atPath: metadataURL.path),
                       let metadata = try? Data(contentsOf: metadataURL),
                       let metadataDict = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any],
                       let interval = metadataDict["expirationInterval"] as? TimeInterval {
                        
                        let expirationDate = modificationDate.addingTimeInterval(interval)
                        
                        if Date() <= expirationDate {
                            // Cache is still valid
                            let data = try Data(contentsOf: URL(fileURLWithPath: cacheFilePath))
                            
                            // Store in memory cache for faster subsequent access
                            storeInMemoryCache(data, for: key, expirationDate: expirationDate)
                            
                            logger.debug("Cache hit (disk) for key: \(key)")
                            return data
                        }
                    }
                }
                
                // Cache has expired, remove it
                try FileManager.default.removeItem(atPath: cacheFilePath)
                // Also remove metadata file if it exists
                let metadataPath = cacheFilePath + ".metadata"
                if FileManager.default.fileExists(atPath: metadataPath) {
                    try FileManager.default.removeItem(atPath: metadataPath)
                }
                logger.debug("Removed expired disk cache for key: \(key)")
            } catch {
                logger.error("Error reading cache file: \(error.localizedDescription)")
            }
        }
        
        logger.debug("Cache miss for key: \(key)")
        return nil
    }
    
    func storeData(_ data: Data, for key: String, expirationInterval: TimeInterval = 3600) {
        // Store in memory cache
        let expirationDate = Date().addingTimeInterval(expirationInterval)
        storeInMemoryCache(data, for: key, expirationDate: expirationDate)
        
        // Store on disk
        storeInDiskCache(data, for: key, expirationInterval: expirationInterval)
        
        logger.debug("Stored \(data.count) bytes in cache for key: \(key)")
    }
    
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAll()
        currentMemoryCacheSize = 0
        
        // Clear disk cache
        do {
            let cacheDirectory = cacheDirectoryURL()
            let fileManager = FileManager.default
            
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in cacheFiles {
                try fileManager.removeItem(at: fileURL)
            }
            
            logger.info("Cache cleared")
        } catch {
            logger.error("Error clearing cache: \(error.localizedDescription)")
        }
    }
    
    func removeExpiredEntries() {
        // Remove expired entries from memory cache
        let expiredKeys = memoryCache.filter { $0.value.isExpired }.map { $0.key }
        
        for key in expiredKeys {
            if let entry = memoryCache.removeValue(forKey: key) {
                currentMemoryCacheSize -= entry.sizeInBytes
            }
        }
        
        // Remove expired entries from disk cache
        do {
            let cacheDirectory = cacheDirectoryURL()
            let fileManager = FileManager.default
            
            let cacheFiles = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            for fileURL in cacheFiles {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    
                    if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
                        // Read expiration interval from a custom property file
                        let metadataURL = fileURL.appendingPathExtension("metadata")
                        if FileManager.default.fileExists(atPath: metadataURL.path),
                           let metadata = try? Data(contentsOf: metadataURL),
                           let metadataDict = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any],
                           let interval = metadataDict["expirationInterval"] as? TimeInterval {
                            
                            let expirationDate = modificationDate.addingTimeInterval(interval)
                            
                            if Date() > expirationDate {
                                try fileManager.removeItem(at: fileURL)
                                // Also remove metadata file
                                try fileManager.removeItem(at: metadataURL)
                            }
                        }
                    }
                } catch {
                    logger.error("Error checking expiration for file \(fileURL.path): \(error.localizedDescription)")
                }
            }
            
            logger.info("Removed expired cache entries")
        } catch {
            logger.error("Error removing expired cache entries: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func storeInMemoryCache(_ data: Data, for key: String, expirationDate: Date) {
        let entry = CacheEntry(data: data, expirationDate: expirationDate)
        
        // If adding this entry would exceed the max cache size, remove oldest entries
        if let existingEntry = memoryCache[key] {
            // Update existing entry size
            currentMemoryCacheSize -= existingEntry.sizeInBytes
        }
        
        // Check if we need to make room in the cache
        if currentMemoryCacheSize + entry.sizeInBytes > maxMemoryCacheSize {
            evictOldestEntries(toFitSize: entry.sizeInBytes)
        }
        
        // Store the new entry
        memoryCache[key] = entry
        currentMemoryCacheSize += entry.sizeInBytes
    }
    
    private func storeInDiskCache(_ data: Data, for key: String, expirationInterval: TimeInterval) {
        let fileURL = cacheFileURL(for: key)
        
        do {
            try data.write(to: fileURL)
            
            // Store expiration interval in a separate metadata file
            let metadataURL = fileURL.appendingPathExtension("metadata")
            let metadata = ["expirationInterval": expirationInterval]
            let metadataData = try JSONSerialization.data(withJSONObject: metadata)
            try metadataData.write(to: metadataURL)
        } catch {
            logger.error("Error writing to disk cache: \(error.localizedDescription)")
        }
    }
    
    private func evictOldestEntries(toFitSize size: Int) {
        // Sort entries by expiration date (oldest first)
        let sortedEntries = memoryCache.sorted { $0.value.expirationDate < $1.value.expirationDate }
        
        var sizeToFree = size - (maxMemoryCacheSize - currentMemoryCacheSize)
        
        for (key, entry) in sortedEntries {
            if sizeToFree <= 0 {
                break
            }
            
            memoryCache.removeValue(forKey: key)
            currentMemoryCacheSize -= entry.sizeInBytes
            sizeToFree -= entry.sizeInBytes
            
            logger.debug("Evicted cache entry for key: \(key)")
        }
    }
    
    private func cacheDirectoryURL() -> URL {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            logger.error("Could not find caches directory; using temporary directory for cache.")
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("net.kartar.wnbaschedule.apicache", isDirectory: true)
        }
        return cacheDirectory.appendingPathComponent("net.kartar.wnbaschedule.apicache", isDirectory: true)
    }
    
    private func cacheFileURL(for key: String) -> URL {
        let cacheDirectory = cacheDirectoryURL()
        let hashedKey = hashKey(key)
        return cacheDirectory.appendingPathComponent(hashedKey)
    }
    
    private func createCacheDirectoryIfNeeded() {
        let cacheDirectory = cacheDirectoryURL()
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: cacheDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                logger.info("Created cache directory at: \(cacheDirectory.path)")
            } catch {
                logger.error("Error creating cache directory: \(error.localizedDescription)")
            }
        }
    }
    
    private func hashKey(_ key: String) -> String {
        guard let data = key.data(using: .utf8) else {
            // Fallback if encoding fails
            return key.replacingOccurrences(of: "[/:?&=]", with: "_", options: .regularExpression)
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
