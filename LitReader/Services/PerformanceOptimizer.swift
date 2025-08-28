import Foundation
import SwiftUI
import Combine

// MARK: - Performance Metrics
struct PerformanceMetrics {
    let timestamp: Date
    let memoryUsage: Int64
    let cpuUsage: Double
    let loadTime: TimeInterval
    let renderTime: TimeInterval
}

// MARK: - Performance Optimizer
@MainActor
class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @Published var isOptimizing = false
    @Published var currentMetrics = PerformanceMetrics(
        timestamp: Date(),
        memoryUsage: 0,
        cpuUsage: 0,
        loadTime: 0,
        renderTime: 0
    )
    
    private var operationTimers: [String: Date] = [:]
    
    private init() {}
    
    // MARK: - Performance Timing
    func startTiming(operation: String) {
        operationTimers[operation] = Date()
    }
    
    func endTiming(operation: String) -> TimeInterval {
        guard let startTime = operationTimers.removeValue(forKey: operation) else {
            return 0
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("操作 \(operation) 耗时: \(String(format: "%.3f", duration))秒")
        return duration
    }
    
    // MARK: - Memory Management
    func optimizeMemoryUsage() async {
        isOptimizing = true
        defer { isOptimizing = false }
        
        // 清理缓存
        clearImageCache()
        
        // 强制垃圾回收
        autoreleasepool {}
        
        print("内存优化完成")
    }
    
    private func clearImageCache() {
        // 清理图片缓存
        URLCache.shared.removeAllCachedResponses()
    }
    
    // MARK: - Performance Monitoring
    func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    func forceOptimization() async {
        await optimizeMemoryUsage()
    }
}