/**
 MIT License

 Copyright (c) 2020 Wendy Liga

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Explorer
import Foundation
import Logging
import mimiq_core

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#elseif os(Windows)
import MSVCRT
#else
import Glibc
#endif

extension Logger {
    /**
     Source: https://github.com/apple/swift-log/blob/a4aa2d5bd9dc80b25f975ac9e195f473f8881012/Sources/Logging/Logging.swift
     */
    private static func currentModule(filePath: String = #file) -> String {
        let utf8All = filePath.utf8
        return filePath.utf8.lastIndex(of: UInt8(ascii: "/")).flatMap { lastSlash -> Substring? in
            utf8All[..<lastSlash].lastIndex(of: UInt8(ascii: "/")).map { secondLastSlash -> Substring in
                filePath[utf8All.index(after: secondLastSlash) ..< lastSlash]
            }
        }.map {
            String($0)
        } ?? "n/a"
    }
    
    private func logMultiline(
        level: Logger.Level,
        message: String,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String,
        function: String,
        line: UInt
    ) {
        message.split(separator: "\n").forEach { perLine in
            self.log(
                level: .debug,
                Logger.Message(stringLiteral: String(perLine)),
                metadata: metadata(),
                source: source() ?? Self.currentModule(),
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    func shellOutput(
        _ message: Shell.SuccessOutput?,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard let message = message else { return }
        logMultiline(
            level: .debug,
            message: message.rawValue,
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }
    
    func shellOutput(
        _ message: Shell.ErrorOutput?,
        metadata: @autoclosure () -> Logger.Metadata? = nil,
        source: @autoclosure () -> String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard let message = message else { return }
        logMultiline(
            level: .error,
            message: message.rawValue,
            metadata: metadata(),
            source: source(),
            file: file,
            function: function,
            line: line
        )
    }
}

extension Logger.Metadata {
    var prettify: String? {
        return !self.isEmpty ? self.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }
}

/**
 Source: https://github.com/apple/swift-log/blob/a4aa2d5bd9dc80b25f975ac9e195f473f8881012/Sources/Logging/Logging.swift
 */
// Prevent name clashes
#if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
let systemStderr = Darwin.stderr
let systemStdout = Darwin.stdout
#elseif os(Windows)
let systemStderr = MSVCRT.stderr
let systemStdout = MSVCRT.stdout
#else
let systemStderr = Glibc.stderr!
let systemStdout = Glibc.stdout!
#endif

/**
 Source: https://github.com/apple/swift-log/blob/a4aa2d5bd9dc80b25f975ac9e195f473f8881012/Sources/Logging/Logging.swift
 */
/// A wrapper to facilitate `print`-ing to stderr and stdio that
/// ensures access to the underlying `FILE` is locked to prevent
/// cross-thread interleaving of output.
internal struct StdioOutputStream: TextOutputStream {
    internal let file: UnsafeMutablePointer<FILE>
    internal let flushMode: FlushMode

    internal func write(_ string: String) {
        string.withCString { ptr in
            #if os(Windows)
            _lock_file(self.file)
            #else
            flockfile(self.file)
            #endif
            defer {
                #if os(Windows)
                _unlock_file(self.file)
                #else
                funlockfile(self.file)
                #endif
            }
            _ = fputs(ptr, self.file)
            if case .always = self.flushMode {
                self.flush()
            }
        }
    }

    /// Flush the underlying stream.
    /// This has no effect when using the `.always` flush mode, which is the default
    internal func flush() {
        _ = fflush(self.file)
    }

    internal static let stderr = StdioOutputStream(file: systemStderr, flushMode: .always)
    internal static let stdout = StdioOutputStream(file: systemStdout, flushMode: .always)

    /// Defines the flushing strategy for the underlying stream.
    internal enum FlushMode {
        case undefined
        case always
    }
}

struct DefaultStdioOutputLogHandler: LogHandler {
    private var prettyMetadata: String?
    
    /**
     Logger's label
     */
    var label: String
    
    /**
     Flag to set verbose mode
     
     default false, so only `info` level log will be print out
     */
    var isVerbose: Bool = false
    
    var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.metadata.prettify
        }
    }
    var logLevel: Logger.Level = .trace // set lowest value
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set(newValue) {
            metadata[metadataKey] = newValue
        }
    }
    
    init(label: String, isVerbose: Bool = false) {
        self.label = label
        self.isVerbose = isVerbose
    }
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let prettyMetadata = metadata?.isEmpty ?? true
            ? self.prettyMetadata
            : (self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new })).prettify
        
        if isVerbose || (!isVerbose && (level == .info || level == .error)) {
            let stream: StdioOutputStream = {
                switch level {
                case .info, .debug, .trace, .notice, .warning:
                    return StdioOutputStream.stdout
                case .error, .critical:
                    return StdioOutputStream.stderr
                }
            }()
            
            var output: [String] = []
            
            if isVerbose {
                output.append("\(level) \(self.label) :\(prettyMetadata.map { " \($0)" } ?? "")")
            }
            
            output.append("\(message)\n")
            
            stream.write(output.joined(separator: " "))
        }
    }
}

struct WriteToFileLogHandler: LogHandler {
    private var prettyMetadata: String?
    
    /**
     Logger's label
     */
    var label: String
    
    var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.metadata.prettify
        }
    }
    var logLevel: Logger.Level = .trace // set lowest value
    var fileName: String
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set(newValue) {
            metadata[metadataKey] = newValue
        }
    }
    
    internal init(label: String, fileName: String) {
        self.label = label
        self.fileName = fileName
    }
    
    /**
     Source: https://github.com/apple/swift-log/blob/a4aa2d5bd9dc80b25f975ac9e195f473f8881012/Sources/Logging/Logging.swift
     */
    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let previousFile = Explorer.default.list(at: logFolder, withFolder: false, isRecursive: false)
            .successValue?
            .compactMap { explorable -> File? in
                guard let file = explorable as? File else { return nil }
                
                return file.name == fileName && file.extension == "log" ? file : nil
            }
            .first
        
        var previousContent = (previousFile?.content ?? "").split(separator: "\n")
        previousContent.append("\(self.timestamp()) \(level) \(self.label) :\(prettyMetadata.map { " \($0)" } ?? "") \(message)\n")
        
        let file = File(name: fileName, content: previousContent.joined(separator: "\n"), extension: "log")
        let operation = SingleFileOperation(file: file, path: logFolder)
        
        Explorer.default.write(operation: operation, writingStrategy: .overwrite)
    }
}
