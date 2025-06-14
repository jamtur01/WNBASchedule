import Foundation
import os.log

/// Manages all application timers (refresh, memory audit, live scores)
class TimerManager {
    // MARK: - Properties
    private var refreshTimer: Timer?
    private var memoryAuditTimer: Timer?
    private var liveScoreTimer: Timer?
    
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    private let liveScoreInterval: TimeInterval = 30 // 30 seconds
    private let memoryAuditInterval: TimeInterval = 1800 // 30 minutes
    
    private let logger = Logger(subsystem: "net.kartar.wnbaschedule", category: "TimerManager")
    
    // MARK: - Public Methods
    
    // MARK: - Refresh Timer
    func setupRefreshTimer(target: AnyObject, selector: Selector) {
        invalidateRefreshTimer()
        
        refreshTimer = Timer.scheduledTimer(
            timeInterval: refreshInterval,
            target: target,
            selector: selector,
            userInfo: nil,
            repeats: true
        )
        
        if let timer = refreshTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        logger.info("Refresh timer started with \(self.refreshInterval)s interval")
    }
    
    func invalidateRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Memory Audit Timer
    func setupMemoryAuditTimer(target: AnyObject, selector: Selector) {
        invalidateMemoryAuditTimer()
        
        memoryAuditTimer = Timer.scheduledTimer(
            timeInterval: memoryAuditInterval,
            target: target,
            selector: selector,
            userInfo: nil,
            repeats: true
        )
        
        if let timer = memoryAuditTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        logger.info("Memory audit timer started with \(self.memoryAuditInterval)s interval")
    }
    
    func invalidateMemoryAuditTimer() {
        memoryAuditTimer?.invalidate()
        memoryAuditTimer = nil
    }
    
    // MARK: - Live Score Timer
    func setupLiveScoreTimer(target: AnyObject, selector: Selector, hasInProgressGames: Bool) {
        invalidateLiveScoreTimer()
        
        guard hasInProgressGames else {
            logger.info("No in-progress games, not starting live score timer")
            return
        }
        
        liveScoreTimer = Timer.scheduledTimer(
            timeInterval: liveScoreInterval,
            target: target,
            selector: selector,
            userInfo: nil,
            repeats: true
        )
        
        if let timer = liveScoreTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        logger.info("Live score timer started with \(self.liveScoreInterval)s interval")
    }
    
    func invalidateLiveScoreTimer() {
        liveScoreTimer?.invalidate()
        liveScoreTimer = nil
    }
    
    // MARK: - Bulk Operations
    func invalidateAllTimers() {
        invalidateRefreshTimer()
        invalidateMemoryAuditTimer()
        invalidateLiveScoreTimer()
        logger.info("All timers invalidated")
    }
    
    func setupAllTimers(
        target: AnyObject,
        refreshSelector: Selector,
        memoryAuditSelector: Selector,
        liveScoreSelector: Selector,
        hasInProgressGames: Bool
    ) {
        setupRefreshTimer(target: target, selector: refreshSelector)
        setupMemoryAuditTimer(target: target, selector: memoryAuditSelector)
        setupLiveScoreTimer(target: target, selector: liveScoreSelector, hasInProgressGames: hasInProgressGames)
    }
}
