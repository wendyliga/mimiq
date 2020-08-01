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

import Foundation
import ConsoleIO

typealias ShellResult = (status: Int32, output: String?, errorOuput: String?)

@discardableResult
func shell(launchPath: String = "/usr/bin/env", arguments: [String]) -> ShellResult {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = ["bash", "-c"] + arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    
    let errorPipe = Pipe()
    task.standardError = errorPipe
    
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorOuput = String(data: errorData, encoding: String.Encoding.utf8)
    
    return (status: task.terminationStatus, output: output, errorOuput: errorOuput)
}

func mustInteruptShell(launchPath: String = "/usr/bin/env", arguments: [String], message: String, completion: @escaping (ShellResult) -> Void) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = ["bash", "-c"] + arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    
    let errorPipe = Pipe()
    task.standardError = errorPipe
    
    DispatchQueue.global(qos: .background).async {
        task.launch()
        
        if !task.isRunning {
            print("❌ Task failed to run")
            Log.default.write("task failed to run")
        }
    }
    
    input(message, defaultValue: "", afterValidation: { _ in
        print("⚙️  Stopping...")
        Log.default.write("stopping simulator recording process")
        
        if task.isRunning {
           task.interrupt()
           Log.default.write("interrupting task...")
        } else {
            print("❌ No Task run")
            Log.default.write("task not running")
        }
    })
    
    task.terminationHandler = { process in
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOuput = String(data: errorData, encoding: String.Encoding.utf8)
        
        Log.default.write("handle completion status \(task.terminationStatus)")
        completion((status: task.terminationStatus, output: output, errorOuput: errorOuput))
    }
}
