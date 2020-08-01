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

class Log {
    static let `default` = Log()
    
    private let dateFormatter = DateFormatter()
    private let logFileName: String
    private let logFileExtension = "log"
    private var logs: [String] = []
    
    init() {
        // Log file name
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        logFileName = dateFormatter.string(from: Date())
    }
    
    @discardableResult
    func write(_ message: String, printOut: Bool = false) -> Result<Bool, Error> {
        if printOut {
            print(message)
        }
        
        dateFormatter.dateFormat = "HH:mm:ss"
        let newLog = "[\(dateFormatter.string(from: Date()))] \(message)"
        logs.append(newLog)
        
        let file = File(name: logFileName, content: logs.joined(separator: "\n"), extension: logFileExtension)
        let operation = SingleFileOperation(file: file, path: logFolder)
        
        let writeOperationResult = Explorer.default.write(operation: operation, writingStrategy: .overwrite)
        guard writeOperationResult.successValue != nil else {
            return .failure(writeOperationResult.failureValue!)
        }
        
        return .success(true)
    }
}
