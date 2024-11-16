//
//  Logs.swift
//  ListenDoctorIosIntegrationDemo
//
//  Created on 13/11/24.
//

import Foundation
import OSLog

/**
 * Log helper. Uses standarized OSLog to log messages
 * - Parameters:
 *   - category: Category of the log
 *   - level: Level of the log
 *   - args: Arguments to log
 *   - file: File where the log is called (automatically filled)
 *   - line: Line where the log is called (automatically filled)
 *   - function: Function where the log is called (automatically filled)
 */
func log(_ category: LogsHelper.Category,
         _ level: OSLogType = .info,
         _ args: String...,
         file: String = #file,
         line: Int = #line,
         function: String = #function)
{
    if #available(iOS 15, *),
       #available(watchOS 8, *),
       #available(watchOSApplicationExtension 8, *)
    {
        let now = Date.now
        var log = "::\(now.formatted(date: .numeric, time: .complete)) \(now.timeIntervalSince1970.description)"
        log += " f: \(file.split(separator: "/").last ?? "") l: \(line.description) \(function.description))\n"
        
        args.forEach({ log += "\t\($0)\n" })
        
        let logger = Logger(subsystem: "L.D", category: "\(category.name)")
        
        logger.log(level: level, "\(log, privacy: .public)")
    }
}

struct LogsHelper {
    
    enum Category {
        
        case api, info, misc, sockets, files, audio, persistency
        
        var name: String {
            
            switch self {
            case .api: return  "API"
            case .info: return "Informative"
            case .misc: return  "Miscellaneous"
            case .sockets: return "Sockets"
            case .files: return "Files"
            case .audio: return "Audio"
            case .persistency: return "Persistency"
            }
        }
    }
}
