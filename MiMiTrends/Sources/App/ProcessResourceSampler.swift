#if os(macOS)
import Darwin
import Foundation

struct ProcessResourceSample: Sendable {
    let footprintBytes: UInt64
    let compressedBytes: UInt64
    let threadCount: Int
}

enum ProcessResourceSampler {
    static func capture() -> ProcessResourceSample {
        var vmInfo = task_vm_info_data_t()
        var vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let vmStatus = withUnsafeMutablePointer(to: &vmInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &vmCount)
            }
        }
        var processInfo = proc_taskinfo()
        let processInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)
        let processStatus = proc_pidinfo(getpid(), PROC_PIDTASKINFO, 0, &processInfo, processInfoSize)
        return ProcessResourceSample(
            footprintBytes: vmStatus == KERN_SUCCESS ? UInt64(vmInfo.phys_footprint) : 0,
            compressedBytes: vmStatus == KERN_SUCCESS ? UInt64(vmInfo.compressed) : 0,
            threadCount: processStatus == processInfoSize ? Int(processInfo.pti_threadnum) : 0
        )
    }
}
#endif
