import Foundation
import os.log
import AppKit

/// A utility for auditing memory usage and detecting potential memory leaks
final class MemoryAudit {
    // MARK: - Properties
    
    /// Shared instance
    static let shared = MemoryAudit()
    
    /// The logger for memory-related logs
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "MemoryAudit")
    
    /// Dictionary to track object allocations
    private var trackedObjects = [ObjectIdentifier: WeakReference]()
    
    /// Lock for thread safety
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        // Register for memory warning notifications
        // Use a valid notification name
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        logger.info("Memory audit system initialized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Tracks an object for potential memory leaks
    /// - Parameters:
    ///   - object: The object to track
    ///   - description: A description of the object for logging
    func trackObject(_ object: AnyObject, description: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let identifier = ObjectIdentifier(object)
        trackedObjects[identifier] = WeakReference(object: object, description: description)
        
        logger.debug("Started tracking object: \(description)")
    }
    
    /// Stops tracking an object
    /// - Parameter object: The object to stop tracking
    func stopTracking(_ object: AnyObject) {
        lock.lock()
        defer { lock.unlock() }
        
        let identifier = ObjectIdentifier(object)
        if let reference = trackedObjects.removeValue(forKey: identifier) {
            logger.debug("Stopped tracking object: \(reference.description)")
        }
    }
    
    /// Performs a memory audit to check for potential leaks
    func performAudit() {
        lock.lock()
        defer { lock.unlock() }
        
        var leakedObjects = 0
        var totalObjects = 0
        
        // Clean up references to deallocated objects
        trackedObjects = trackedObjects.filter { _, reference in
            totalObjects += 1
            if reference.object == nil {
                return false
            }
            return true
        }
        
        // Log potential leaks
        for (_, reference) in trackedObjects where reference.object != nil {
            leakedObjects += 1
            logger.warning("Potential memory leak: \(reference.description)")
        }
        
        logger.info("Memory audit completed: \(leakedObjects) potential leaks out of \(totalObjects) tracked objects")
    }
    
    /// Returns the current memory usage in bytes
    func currentMemoryUsage() -> UInt64 {
        var info = MachTaskBasicInfo()
        var count = mach_msg_type_number_t(MemoryLayout<MachTaskBasicInfo>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(machTaskBasicInfo),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.residentSize
        } else {
            logger.error("Failed to get memory usage: \(kerr)")
            return 0
        }
    }
    
    /// Formats memory size for display
    /// - Parameter bytes: The size in bytes
    /// - Returns: A formatted string (e.g., "15.2 MB")
    func formatMemorySize(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.1f KB", kb)
        }
    }
    
    // MARK: - Private Methods
    
    @objc
    private func didReceiveMemoryWarning() {
        logger.warning("Received memory warning! Current usage: \(self.formatMemorySize(self.currentMemoryUsage()))")
        performAudit()
    }
}

// MARK: - Weak Reference

/// A weak reference wrapper to avoid retain cycles in the tracking system
private class WeakReference {
    weak var object: AnyObject?
    let description: String
    
    init(object: AnyObject, description: String) {
        self.object = object
        self.description = description
    }
}

// MARK: - NSObject Extension

extension NSObject {
    /// Tracks this object for potential memory leaks
    /// - Parameter description: A description of the object for logging
    func trackForMemoryLeak(description: String? = nil) {
        let desc = description ?? String(describing: type(of: self))
        MemoryAudit.shared.trackObject(self, description: desc)
    }
    
    /// Stops tracking this object
    func stopMemoryTracking() {
        MemoryAudit.shared.stopTracking(self)
    }
}

// MARK: - Mach Task Info

private struct MachTaskBasicInfo {
    var virtualSize: UInt64 = 0
    var residentSize: UInt64 = 0
    var residentSizeMax: UInt64 = 0
    var userTime: UInt64 = 0
    var systemTime: UInt64 = 0
    var policy: Int32 = 0
    var suspendCount: Int32 = 0
}

private let machTaskBasicInfo = 20
