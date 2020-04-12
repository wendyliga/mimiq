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
import Explorer
import Foundation

// MARK: - Configuration

private let appName = "mimiq"
private let version = "0.3.6"

// Environment setup params
private let defaultResultPath = "~/Desktop/"
private let documentPath = "~/"
private let mimiqFolder = documentPath + ".mimiq/"
private let logFolder = mimiqFolder + "log/"
private let tempFolder = mimiqFolder + "temp/"

// MARK: - Logging

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

// MARK: - Setup Environment

func configureEnvironment() -> Result<SingleFolderOperation, Error> {
    let tempFolder = Folder(name: "temp", contents: [])
    let logFolder = Folder(name: "log", contents: [])
    let mimiqFolder = Folder(name: ".mimiq", contents: [tempFolder, logFolder])
    
    let operation = SingleFolderOperation(folder: mimiqFolder, path: documentPath)
    return Explorer.default.write(operation: operation, writingStrategy: .skippable)
}

// MARK: - Remove Cache

func removeCache() {
    // delete created file
    // TODO: convert it to Explorer
    Log.default.write(#"remove temp folder output \#(shell(arguments: ["rm -rf \(tempFolder)"]))"#)
}

// MARK: - Argument

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "list",
      abstract: "List Available Simulator",
      discussion: ""
    )
    
    #if DEBUG
    enum Mode: String, ExpressibleByArgument {
        case available
        case none
        
        var shellProvider: ShellProvider {
            switch self {
            case .available:
                return AvailableSimulatorShellProvider()
            case .none:
                return NoneSimulatorShellProvider()
            }
        }
    }
    
    @Option(name: .long, help: "Mock Mode For Testing Purpose")
    var mode: Mode?
    #endif
    
    func run() throws {
        #if DEBUG
        let shellProvider: ShellProvider = mode != nil ? mode!.shellProvider : DefaultShellProvider.shared
        #else
        let shellProvider = DefaultShellProvider.shared
        #endif
        
        let availableSimulators = shellProvider.availableSimulators
        guard availableSimulators.isNotEmpty else {
            print("💥 No Available Simulator to mimiq"); return
        }
        
        print("Available Simulator to mimiq: ")
        availableSimulators.forEach { simulator in
            print("✅ \(simulator.udid) \(simulator.name)")
        }
    }
}

struct Version: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "version",
      abstract: "\(appName) version",
      discussion: ""
    )
    
    func run() throws {
        print("current version \(version)")
    }
}

struct Cache: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "clear-cache",
      abstract: "clear all mimiq process cache",
      discussion: ""
    )
    
    func run() throws {
        removeCache()
    }
}

struct Record: ParsableCommand {
    init() {}
    
    #if DEBUG
    static var configuration = CommandConfiguration(
        commandName: "record",
        abstract:
        """

        Record your Xcode simulator and convert it to GIF
        """,
        discussion:
        """
        mode for testing purpose:
        \(Mode.allCases
            .map { "- " + $0.rawValue }
            .joined(separator: "\n"))
        """
    )
    #else
    static var configuration = CommandConfiguration(
      commandName: "record",
      abstract:
        """
        Record your Xcode simulator and convert it to GIF
        
        """
    )
    #endif
    
    @Option(help: "Destination path you want to place \(appName) generated GIF")
    var path: String?
    
    @Option(help: "Select Spesific simulator based on its UDID, run `\(appName) list` to check available simulator")
    var udid: String?
    
    @Flag(name: .short, help: "Execute mimiq with verbose log")
    var isVerbose: Bool
    
    #if DEBUG
    enum Mode: String, ExpressibleByArgument, CaseIterable {
        case noHomebrew
        case noFFMpeg
        case noSimulator
        case failRecord
        case failMakeGIF
        case success
        
        var shellProvider: ShellProvider {
            switch self {
            case .noHomebrew:
                return NoHomebrewShellProvider()
            case .noFFMpeg:
                return NoFFMpegShellProvider()
            case .noSimulator:
                return NoneSimulatorShellProvider()
            case .failRecord:
                return FailedRecordShellProvider()
            case .failMakeGIF:
                return FailedConvertingGIFShellProvider()
            case .success:
                return SuccessShellProvider()
            }
        }
    }
    
    @Option(name: .long, help: "Mock Mode For Testing Purpose")
    var mode: Mode?
    #endif
    
    /**
     ShellProvider is the abstract class that provide shell operation for mimiq
     
     this abstraction is important to test purpose
     */
    private var shellProvider: ShellProvider {
        #if DEBUG
        return mode != nil ? mode!.shellProvider : DefaultShellProvider.shared
        #else
        return DefaultShellProvider.shared
        #endif
    }
    
    /**
     The path user or defaultly set to place the generated GIF
     */
    private var resultPath: String {
        guard let customPath = path else {
            return defaultResultPath
        }
        
        return customPath
    }
    
    /**
     The filename mimiq will use as GIF result filename
     
     the default filename will be mimiq.gif
     if there's any previous mimiq result, then the filename will be have number suffix appending based on latest increment number
     
     for example: mimiq10.gif
     */
    private var mimiqFileName: String {
        // Current list file on target path for GIF
        guard let listFiles = shellProvider.list(at: resultPath, withFolder: false, isRecursive: false).successValue else {
            return "mimiq"
        }
        
        // get last increment number
        let fileWithMimiqPrefix = listFiles
            .compactMap { explorable -> String? in
                guard let file = explorable as? File else {
                    return nil
                }
                
                return file.name.hasPrefix("mimiq") ? file.name : nil
            }
            
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
    
    /**
     The simulator target mimiq will use to record
     
     for default, mimiq will use the first available simulator or if user determine spesific simulator
     */
    private var mimiqTarget: Simulator? {
        let availableSimulator = shellProvider.availableSimulators
        
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
        log("mimiq start to run")
        
        // MARK: - Check Not Linux
        
        #if os(Linux)
        log("mimiq is running on linux", printOut: isVerbose)
        print("\(appName) is not support linux yet")
        Darwin.exit(EXIT_FAILURE)
        #endif
        
        log("mimiq is running on mac")
        
        // log computer info, like os version
        logShellOutput(shell(arguments: ["sw_vers"]).output)
        
        // MARK: - Configure Environment
        
        guard configureEnvironment().successValue != nil else {
            log("failed setup environment")
            
            print("💥 Failed to Setup Enviroment")
            Darwin.exit(EXIT_FAILURE)
        }
        
        log("environment setup success")
        
        // MARK: - Check Homebrew Installed
        
        guard shellProvider.isHomebrewInstalled else {
            log("missing homebrew")
            
            print("💥 Missing Homebrew, please install Homebrew, for more visit https://brew.sh")
            Darwin.exit(EXIT_FAILURE)
        }
        
        log("Homebrew is installed")
        logShellOutput(shell(arguments: ["brew --version"]).output)
        
        // MARK: - Check FFMpeg Installed
        
        guard shellProvider.isFFMpegInstalled else {
            log("missing ffmpeg")
            
            print("💥 Missing FFMpeg, please install mpeg, by executing `brew install ffmpeg`")
            Darwin.exit(EXIT_FAILURE)
        }
        
        // MARK: - Unwarp Mimiq Target
        
        guard let mimiqTarget = mimiqTarget else {
            log("no available simulator")
            
            print("💥 No Available Simulator to mimiq")
            Darwin.exit(EXIT_FAILURE)
        }
        
        log("simulator target \(mimiqTarget)")
        
        // MARK: - Record Simulator
        
        // mov path
        let movSource = tempFolder + UUID().uuidString + ".mov"
        
        log("simulator to record on \(movSource)")
        
        // log xcode version
        let xcodeBuildVersion = shell(arguments: ["xcodebuild -version"])
        logShellOutput(xcodeBuildVersion.output ?? "no ouput")
        logShellOutput(xcodeBuildVersion.errorOuput ?? "no error ouput")
        
        let recordResult = shellProvider.recordSimulator(target: mimiqTarget, movTarget: movSource, printOutLog: isVerbose)

        log("record simulator finish with status \(recordResult.status)")
        guard recordResult.status == 0 else {
            removeCache()
            log("error record simulator")
            logShellOutput(recordResult.output ?? "no ouput")
            logShellOutput(recordResult.errorOuput ?? "no error ouput")
            
            print("💥 Record Failed, Please Try Again")
            Darwin.exit(EXIT_FAILURE)
        }
        
        log("stop recording")
        
        // MARK: - Convert Mov to Gif
        
        log("start creating GIF")
        print("⚙️  Creating GIF..")
        
        let gifTargetPath = resultPath + mimiqFileName + ".gif"
        let generateGIFResult = shellProvider.convertMovToGif(movSource: movSource, gifTarget: gifTargetPath, printOutLog: isVerbose)
        
        guard generateGIFResult.status == 0 else {
            // clear generated cache
            removeCache()
            log("error generating GIF")
            logShellOutput(generateGIFResult.output ?? "no ouput")
            logShellOutput(generateGIFResult.errorOuput ?? "no error ouput")
            
            print("💥 Failed on Creating GIF, Please Try Again")
            Darwin.exit(EXIT_FAILURE)
        }
        
        log("success generating GIF")
        logShellOutput(generateGIFResult.output)
        
        removeCache() // clear generated cache
        
        log("GIF generated at \(gifTargetPath)")
        print("✅ Grab your GIF at \(gifTargetPath)")
    }
    
    private func log(_ message: String) {
        Log.default.write(message, printOut: isVerbose)
    }
    
    private func logShellOutput(_ output: String?) {
        guard let output = output else { return }
        
        output.split(separator: "\n").forEach { eachLine in
            log(String(eachLine))
        }
    }
}

struct Main: ParsableCommand {
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
        subcommands: [Record.self, List.self, Version.self, Cache.self],
        defaultSubcommand: Record.self
    )
}

Main.main()
