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

import ArgumentParser
import ConsoleIO
import Explorer
import Foundation

// MARK: - Configuration

private let appName = "mimiq"
private let version = "0.3.1"
private let defaultResultPath = "~/Desktop/"
private let documentPath = "~/"
private let mimiqFolder = documentPath + ".mimiq/"
private let logFolder = mimiqFolder + "log/"
private let tempFolder = mimiqFolder + "temp/"

struct Runtime: Decodable {
    let identifier: String
}

struct Simulator: Decodable {
    let udid: UUID
    let name: String
}

extension JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data, keyPath: String) throws -> T {
        let toplevel = try JSONSerialization.jsonObject(with: data)
        
        if let nestedJson = (toplevel as AnyObject).value(forKeyPath: keyPath) {
            let nestedJsonData = try JSONSerialization.data(withJSONObject: nestedJson)
            return try decode(type, from: nestedJsonData)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Nested json not found for key path \"\(keyPath)\""))
        }
    }
}

extension String {
    /**
     Remove file extension from filename
     */
    func withoutExtension(replaceWith newString: String = "") -> String {
        var dotIndex: Int?
        var isDotFound = false
        
        for (index, character) in self.enumerated().reversed() {
            guard !isDotFound else { break }
            
            if character == "." && !isDotFound {
                dotIndex = index
                isDotFound = true
            }
        }
        
        guard let unwarpDotIndex = dotIndex else {
            return self
        }
        
        let startDotIndex = index(startIndex, offsetBy: unwarpDotIndex)
        return replacingCharacters(in: startDotIndex..<endIndex, with: newString)
    }
}

func explorableMimiqFilename(_ explorable: Explorable) -> String? {
    guard let file = explorable as? File else {
        return nil
    }
    
    return file.name.hasPrefix("mimiq") ? file.name : nil
}

@discardableResult
func shell(launchPath: String = "/usr/bin/env", arguments: [String]) -> (status: Int32, output: String?) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = ["bash", "-c"] + arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return (status: task.terminationStatus, output: output)
}

func mustInteruptShell(launchPath: String = "/usr/bin/env", arguments: [String], message: String) -> (status: Int32, output: String?) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = ["bash", "-c"] + arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    
    DispatchQueue.global(qos: .background).async {
        task.launch()
    }
    
    input(message, defaultValue: "", afterValidation: { _ in
        task.interrupt()
    })
    
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return (status: task.terminationStatus, output: output)
}

func configureEnvironment() -> Result<SingleFolderOperation, Error> {
    let movFolder = Folder(name: "mov", contents: [])
    let logFolder = Folder(name: "log", contents: [])
    let mimiqFolder = Folder(name: ".mimiq", contents: [movFolder, logFolder])
    
    let operation = SingleFolderOperation(folder: mimiqFolder, path: documentPath)
    return Explorer.default.write(operation: operation, writingStrategy: .skippable)
}

func removeCache() {
    // delete created file
    // TODO: convert it to Explorer
    try? FileManager.default.removeItem(atPath: tempFolder)
}

var isHomebrewInstalled: Bool {
    shell(arguments: [#"! homebrew_loc="$(type -p "brew")" || [[ -z $homebrew_loc ]];"#]).status == 1
}

var isFFMpegInstalled: Bool {
    shell(arguments: [#"! ffmpeg_loc="$(type -p "ffmpeg")" || [[ -z $ffmpeg_loc ]];"#]).status == 1
}

var simulators: [Simulator] {
    let simulatorRuntimeListShellExecution = shell(arguments: ["xcrun simctl list -v runtimes --json"])
    guard
        simulatorRuntimeListShellExecution.status == 0,
        let runtimeListRawData = simulatorRuntimeListShellExecution.output?.data(using: .utf8),
        let runtimes = try? JSONDecoder().decode([Runtime].self, from: runtimeListRawData, keyPath: "runtimes")
    else {
        return []
    }
    /**
     
     because json structer from simctl looks like this
     
     {
       "devices" : {
         "com.apple.CoreSimulator.SimRuntime.tvOS-13-3" : [
            ... list devices ...
         ],
         "com.apple.CoreSimulator.SimRuntime.watchOS-6-1" : [
            ... list devices ...
         ],
       }
     }
     
     there's no way to map inside device json object with decodable, so JSONSerialization comes in help
     */
    
    let simulatorListShellExecution = shell(arguments: ["xcrun simctl list -v devices booted --json"])
    guard
        simulatorListShellExecution.status == 0,
        let simulatorListRawData = simulatorListShellExecution.output?.data(using: .utf8),
        let simulatorListJsonSerialization = try? JSONSerialization.jsonObject(with: simulatorListRawData, options: .allowFragments) as? [String: Any],
        let deviceJsonSeralization = simulatorListJsonSerialization["devices"] as? [String: [[String: Any]]]
    else {
        return []
    }
    
    return runtimes.map { runtime -> [Simulator] in
        guard let devices = deviceJsonSeralization[runtime.identifier] else { return [] }
        
        return devices.compactMap { device -> Simulator? in
            guard let deviceUdidRawValue = device["udid"] as? String, let udid = UUID(uuidString: deviceUdidRawValue), let name = device["name"] as? String else {
                return nil
            }
            
            return Simulator(udid: udid, name: name)
        }
    }.flatMap { $0 }
}

// MARK: - Argument

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "list",
      abstract: "List Available Simulator",
      discussion: "",
      helpNames: .long
    )
    
    func run() throws {
        let availableSimulators = simulators
        guard availableSimulators.isNotEmpty else {
            print("💥 No Available Simulator to mimiq"); return
        }
        
        print("Available Simulator to mimiq: ")
        simulators.forEach { simulator in
            print("✅ \(simulator.udid) \(simulator.name)")
        }
    }
}

struct Version: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "version",
      abstract: "\(appName) version",
      discussion: "",
      helpNames: .long
    )
    
    func run() throws {
        print("current version \(version)")
    }
}

struct Cache: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "clear-cache",
      abstract: "clear all mimiq process cache",
      discussion: "",
      helpNames: .long
    )
    
    func run() throws {
        removeCache()
    }
}

struct Mimiq: ParsableCommand {
    init() {}
    
    static var configuration = CommandConfiguration(
      commandName: appName,
      abstract:
        """
        Record your Xcode simulator and convert it to GIF
        """,
      discussion:
        """
        \(appName) \(version)
        
        Created by Wendy Liga
        Learn more https://github.com/wendyliga/mimiq
        """,
      subcommands: [List.self, Version.self, Cache.self],
      helpNames: .long
    )
    
    @Option(help: "Destination path you want to place \(appName) generated GIF")
    var path: String?
    
    @Option(help: "Select Spesific simulator based on its UDID, run `\(appName) list` to check available simulator")
    var udid: String?
    
    @Flag(name: .short, help: "Execute mimiq with verbose log")
    var isVerbose: Bool
    
    private var resultPath: String {
        guard let customPath = path else {
            return defaultResultPath
        }
        
        return customPath
    }
    
    private var mimiqFileName: String {
        // Current list file on target path for GIF
        guard let listFiles = Explorer.default.list(at: resultPath, withFolder: false, isRecursive: false).successValue else {
            return "mimiq"
        }
        
        // get last increment number
        let fileWithMimiqPrefix = listFiles
            .compactMap(explorableMimiqFilename)
            
        let lastMimiqIncrementNumber = fileWithMimiqPrefix
            .compactMap { Int($0.withoutPrefix("mimiq")) }
            .sorted()
            .last
        
        /**
         if no increment number, then use default increment number
         */
        let defaultPrefix = fileWithMimiqPrefix.isNotEmpty ? "1" : ""
        
        /**
         add prefix on mimiq file, for increment purpose
         */
        let prefix = lastMimiqIncrementNumber != nil ? String(lastMimiqIncrementNumber! + 1) : defaultPrefix
        
        return "mimiq" + prefix
    }
    
    private var mimiqTarget: Simulator? {
        let availableSimulator = simulators
        
        guard availableSimulator.isNotEmpty else {
            return nil
        }
        
        if let udidRawValue = udid, let udid = UUID(uuidString: udidRawValue) {
            return availableSimulator
                .filter { $0.udid == udid }
                .first
        } else {
            return availableSimulator.first
        }
    }
    
    func run() throws {
        #if os(Linux)
            print("\(appName) is not support linux yet")
            return
        #endif
        
        guard configureEnvironment().successValue != nil else {
            print("💥 Failed to Setup Enviroment"); return
        }
        
        guard isHomebrewInstalled else {
            print("💥 Missing Homebrew, please install Homebrew, for more visit https://brew.sh"); return
        }
        
        if !isFFMpegInstalled {
            print("⚙️ Missing ffmpeg, installing...(This may take a while)")
            
            let command = "brew install ffmpeg" + (isVerbose ? "" : " >/dev/null")
            shell(arguments: [command])
        }
            
        
        guard let mimiqTarget = mimiqTarget else {
            print("💥 No Available Simulator to mimiq"); return
        }
        
        // Start Recording
        let movRawFileName = UUID().uuidString
        let movFileName = movRawFileName + ".mov"
        let movSource = tempFolder + movFileName

        let recordCommand = "xcrun simctl io \(mimiqTarget.udid.uuidString) recordVideo -f \(movSource)" + (isVerbose ? "" : " &> /dev/null")
        let recordMessage = "🔨 Recording Simulator \(mimiqTarget.name) with UDID \(mimiqTarget.udid)... Press Enter to Stop.)"
        let recordResult = mustInteruptShell(arguments: [recordCommand], message: recordMessage)

        guard recordResult.status == 0 else {
            removeCache()
            print("💥 Record Failed, Please Try Again"); return
        }

        print("⚙️ Creating GIF..")
        
        let gifTargetPath = resultPath + mimiqFileName + ".gif"
        
        let setPallete = #"palette="/tmp/palette.png""#
        let configureFilter = #"filters="fps=15,scale=320:-1:flags=lanczos""#
        let slicingVideo = #"ffmpeg -nostdin -v warning -i \#(movSource) -vf "$filters,palettegen=stats_mode=diff" -y $palette"# + (isVerbose ? "" : " &> /dev/null")
        let createGIF = #"ffmpeg -nostdin -i \#(movSource) -i $palette -loglevel panic -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y \#(gifTargetPath)"# + (isVerbose ? "" : " &> /dev/null")
        let generateGIFCommand = [setPallete, configureFilter , slicingVideo, createGIF].joined(separator: ";")
        
        guard shell(arguments: [generateGIFCommand]).status == 0 else {
            // clear generated cache
            removeCache()
            print("💥 Failed on Creating GIF, Please Try Again"); return
        }
        
        // clear generated cache
        removeCache()
        
        print("✅ Grab your GIF at \(gifTargetPath)")
        
    }
}

Mimiq.main()
