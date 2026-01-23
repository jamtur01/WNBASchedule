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
    
    /// Current memory cache size in bytes (computed from actual cache entries)
    private var currentMemoryCacheSize: Int {
        memoryCache.values.reduce(0) { $0 + $1.sizeInBytes }
    }
    
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
        let cacheFileURL = cacheFileURL(for: key)
        let expirationCheck = checkDiskCacheExpiration(at: cacheFileURL)
        
        if !expirationCheck.isExpired, let expirationDate = expirationCheck.expirationDate {
            // Cache is still valid
            do {
                let data = try Data(contentsOf: cacheFileURL)
                
                // Store in memory cache for faster subsequent access
                storeInMemoryCache(data, for: key, expirationDate: expirationDate)
                
                logger.debug("Cache hit (disk) for key: \(key)")
                return data
            } catch {
                logger.error("Error reading cache file: \(error.localizedDescription)")
            }
        } else if expirationCheck.isExpired {
            // Cache has expired, remove it
            removeExpiredCacheFile(at: cacheFileURL)
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
        // currentMemoryCacheSize is computed, so no need to reset
        
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
            memoryCache.removeValue(forKey: key)
            // currentMemoryCacheSize is computed, so no need to manually update
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
                let expirationCheck = checkDiskCacheExpiration(at: fileURL)
                if expirationCheck.isExpired {
                    removeExpiredCacheFile(at: fileURL)
                }
            }
            
            logger.info("Removed expired cache entries")
        } catch {
            logger.error("Error removing expired cache entries: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks if a disk cache entry is expired
    /// - Parameter fileURL: URL of the cache file
    /// - Returns: Tuple containing (isExpired: Bool, expirationDate: Date?) - expirationDate is nil if file doesn't exist or metadata is invalid
    private func checkDiskCacheExpiration(at fileURL: URL) -> (isExpired: Bool, expirationDate: Date?) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return (isExpired: true, expirationDate: nil)
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            guard let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date else {
                return (isExpired: true, expirationDate: nil)
            }
            
            // Read expiration interval from metadata file
            let metadataURL = fileURL.appendingPathExtension("metadata")
            guard FileManager.default.fileExists(atPath: metadataURL.path),
                  let metadata = try? Data(contentsOf: metadataURL),
                  let jsonObject = try? JSONSerialization.jsonObject(with: metadata, options: []),
                  let metadataDict = jsonObject as? [String: Any],
                  let interval = metadataDict["expirationInterval"] as? TimeInterval else {
                return (isExpired: true, expirationDate: nil)
            }
            
            let expirationDate = modificationDate.addingTimeInterval(interval)
            let isExpired = Date() > expirationDate
            
            return (isExpired: isExpired, expirationDate: expirationDate)
        } catch {
            logger.error("Error checking cache expiration for \(fileURL.path): \(error.localizedDescription)")
            return (isExpired: true, expirationDate: nil)
        }
    }
    
    /// Removes expired cache file and its metadata
    /// - Parameter fileURL: URL of the cache file to remove
    private func removeExpiredCacheFile(at fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            let metadataURL = fileURL.appendingPathExtension("metadata")
            if FileManager.default.fileExists(atPath: metadataURL.path) {
                try FileManager.default.removeItem(at: metadataURL)
            }
            logger.debug("Removed expired disk cache for key: \(fileURL.lastPathComponent)")
        } catch {
            logger.error("Error removing expired cache file: \(error.localizedDescription)")
        }
    }
    
    private func storeInMemoryCache(_ data: Data, for key: String, expirationDate: Date) {
        let entry = CacheEntry(data: data, expirationDate: expirationDate)
        
        // Check if we need to make room in the cache
        // Remove existing entry first if updating
        if memoryCache[key] != nil {
            // Entry will be replaced, so we'll check size after removal
        }
        
        // Calculate size after adding this entry
        let sizeAfterAdd = currentMemoryCacheSize - (memoryCache[key]?.sizeInBytes ?? 0) + entry.sizeInBytes
        
        if sizeAfterAdd > maxMemoryCacheSize {
            evictOldestEntries(toFitSize: entry.sizeInBytes)
        }
        
        // Store the new entry
        memoryCache[key] = entry
        // currentMemoryCacheSize is computed, so no need to manually update
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
        let currentSize = currentMemoryCacheSize
        let sizeToFree = size - (maxMemoryCacheSize - currentSize)
        
        // If we already have enough space, no need to evict
        guard sizeToFree > 0 else { return }
        
        // Sort entries by expiration date (oldest first)
        let sortedEntries = memoryCache.sorted { $0.value.expirationDate < $1.value.expirationDate }
        
        var remainingSizeToFree = sizeToFree
        
        for (key, entry) in sortedEntries {
            if remainingSizeToFree <= 0 {
                break
            }
            
            memoryCache.removeValue(forKey: key)
            remainingSizeToFree -= entry.sizeInBytes
            
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
