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

#if os(Linux)
import Glibc
#elseif os(OSX)
import Darwin
#elseif os(Windows)
import MSVCRT
#endif

import ArgumentParser
import Explorer
import Foundation
import Logging
import mimiq_core

// MARK: - Configuration

let appName = "mimiq"

// Environment setup params
let defaultResultPath = "~/Desktop/"
let documentPath = "~/"
let mimiqFolder = documentPath + ".mimiq/"
let logFolder = mimiqFolder + "log/"
let tempFolder = mimiqFolder + "temp/"

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
    Shell.execute(arguments: ["rm -rf \(tempFolder)"])
}

// MARK: - Argument

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "list",
      abstract: "List Available Simulator",
      discussion: ""
    )
    
    @Flag(help: "Output available simulator to mimiq with JSON format")
    var json: Bool = false
    
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
            print(json ? "[]" : "💥 No Available Simulator to mimiq"); return
        }
        
        var outputs = [String]()
        
        if json {
            let jsonEncoder = JSONEncoder()
            
            do {
                let jsonData = try jsonEncoder.encode(availableSimulators)
                outputs.append(String(data: jsonData, encoding: .utf8) ?? "[]")
            } catch {
                outputs.append("[]")
            }
        } else {
            outputs.append("Available Simulator to mimiq: ")
            outputs.append(contentsOf: availableSimulators.map { "✅ \($0.udid) \($0.name)" })
        }
        
        print(outputs.joined(separator: "\n"))
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
      abstract: "Clear all mimiq process cache",
      discussion: ""
    )
    
    func run() throws {
        removeCache()
    }
}

struct OutputTypeList: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "output-type",
      abstract: "List all output types",
      discussion: ""
    )
    
    func run() throws {
        print("Available Output Type")
        
        OutputType.allCases.forEach { value in
            print("- \(value)")
        }
    }
}

struct QualityList: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "quality",
      abstract: "List available quality",
      discussion: ""
    )
    
    func run() throws {
        print("Available Quality")
        
        GIFQuality.allCases.forEach { quality in
            print("- \(quality)")
        }
    }
}

struct Record: ParsableCommand {
    init() {}
    
    #if DEBUG
    static var configuration = CommandConfiguration(
        commandName: "record",
        abstract:
        """

        Record your Xcode simulator and convert it to GIF, MP4 or Mov
        """,
        discussion:
        """
        mode for testing purpose:
        \(Mode.allCases
            .map { "- " + $0.rawValue }
            .joined(separator: "\n"))
        """,
        subcommands: [
            QualityList.self,
            OutputTypeList.self
        ]
    )
    #else
    static var configuration = CommandConfiguration(
      commandName: "record",
      abstract:
        """
        Record your Xcode simulator and convert it to GIF, MP4 or Mov
        
        """,
        subcommands: [Quality.self]
    )
    #endif
    
    @Option(help: "Destination path you want to place \(appName) output")
    var path: String?
    
    @Option(help: "Select Spesific simulator based on its UDID, run `\(appName) list` to check available simulator")
    var udid: String?
    
    @Option(
        name: .customLong("custom-ffmpeg"),
        help: "Use Custom FFMpeg, provide it with the path to FFMpeg Binary Directory, Please Refer the Directory and not the Binary."
    )
    var customFFMpegPath: String?
    
    @Option(
        name: .shortAndLong,
        help: "select output type, use mimiq record "
    )
    var output: OutputType = .gif
    
    @Option(
        name: .shortAndLong,
        help: "Determine what GIF quality mimiq will output, default will be medium. only needed if you select `gif` as output"
    )
    var quality: GIFQuality = .medium
    
    @Flag(name: .short, help: "Execute mimiq with verbose log")
    var isVerbose: Bool = false
    
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
        if let mode = mode {
            return mode.shellProvider
        } else {
            return DefaultShellProvider.shared
        }
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let logFileName = dateFormatter.string(from: Date())
        
        var logger = Logger(label: "record") { label -> LogHandler in
            return MultiplexLogHandler([
                DefaultStdioOutputLogHandler(label: label, isVerbose: isVerbose),
                WriteToFileLogHandler(label: label, fileName: logFileName)
            ])
        }
        logger.debug("mimiq start to run")
        
        // MARK: - Check Not Linux
        
        #if os(Linux)
        logger.debug("mimiq is running on linux")
        logger.notice("\(appName) is not support linux yet")
        Glibc.exit(EXIT_FAILURE)
        #endif
        
        defer {
            removeCache() // clear generated cache
        }
        
        logger.debug("mimiq is running on mac")
        logger.shellOutput(Shell.execute(arguments: ["sw_vers"]).output) // log computer info, like os version
        
        // MARK: - Configure Environment
        
        guard configureEnvironment().successValue != nil else {
            logger.debug("failed setup environment")
            logger.error("💥 Failed to Setup Enviroment")
            Darwin.exit(EXIT_FAILURE)
        }
        
        logger.debug("environment setup success")
        
        // MARK: - Check Homebrew Installed
        
        // only on default ffmpeg
        if customFFMpegPath == nil {
            guard shellProvider.isHomebrewInstalled else {
                logger.debug("missing homebrew")
                
                logger.error("💥 Missing Homebrew, please install Homebrew, for more visit https://brew.sh")
                Darwin.exit(EXIT_FAILURE)
            }
            
            logger.debug("Homebrew is installed")
            logger.shellOutput(Shell.execute(arguments: ["brew --version"]).output)
        }
        
        
        // MARK: - Check FFMpeg Installed
        
        // only on default ffmpeg
        if customFFMpegPath == nil {
            guard shellProvider.isFFMpegInstalled else {
                logger.debug("missing ffmpeg")
                logger.error("💥 Missing FFMpeg, please install mpeg, by executing `brew install ffmpeg`")
                Darwin.exit(EXIT_FAILURE)
            }
        }
        
        // MARK: - Unwarp Mimiq Target
        
        guard let mimiqTarget = mimiqTarget else {
            logger.debug("no available simulator")
            logger.error("💥 No Available Simulator to mimiq")
            Darwin.exit(EXIT_FAILURE)
        }
        
        logger.debug("simulator target \(mimiqTarget)")
        
        // MARK: - Record Simulator
        
        // mov path
        let movSource = tempFolder + UUID().uuidString + ".mov"
        
        logger.debug("simulator to record on \(movSource)")
        
        // log xcode version
        let xcodeBuildVersion = Shell.execute(arguments: ["xcodebuild -version"])
        logger.shellOutput(xcodeBuildVersion.output ?? "no ouput")
        logger.shellOutput(xcodeBuildVersion.errorOuput ?? "no error ouput")
        
        // dispatch group for hold execution and waiting for async task of record simulator
        let group = DispatchGroup()
        group.enter()
        
        // start record simulator
        shellProvider.recordSimulator(target: mimiqTarget, movTarget: movSource, logger: logger, completion: { recordResult in
            logger.debug("record simulator finish with status \(recordResult.status)")
            
            guard recordResult.status == 0 else {
                removeCache()
                logger.debug("error record simulator")
                logger.shellOutput(recordResult.output ?? "no ouput")
                logger.shellOutput(recordResult.errorOuput ?? "no error ouput")
                logger.error("💥 Record Failed, Please Try Again")
                Darwin.exit(EXIT_FAILURE)
            }
            
            logger.debug("stop recording")
            
            /// inform DispatchGroup to continue
            group.leave()
        })
        
        /// wait until async `recordSimulator` finish
        group.wait()
        
        // MARK: - Convert Mov to Gif
        
        logger.debug("start creating output")
        logger.info("⚙️ Creating output...")
        
        let outputTargetPath = resultPath + mimiqFileName + "." + output.fileExtension
        let generateOutputResult = shellProvider.generateOutput(
            output,
            movSource: movSource,
            outputTarget: outputTargetPath,
            quality: quality,
            customFFMpegPath: customFFMpegPath,
            logger: logger
        )
        
        guard generateOutputResult.status == 0 else {
            // clear generated cache
            removeCache()
            logger.debug("error generating output")
            logger.shellOutput(generateOutputResult.output)
            logger.shellOutput(generateOutputResult.errorOuput)
            logger.error("💥 Failed on Creating output, Please Try Again")
            Darwin.exit(EXIT_FAILURE)
        }
        
        logger.debug("success generating output")
        logger.shellOutput(generateOutputResult.output ?? "")
        logger.debug("output generated at \(outputTargetPath)")
        logger.info("✅ Grab your output at \(outputTargetPath)")
    }
}

struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: appName,
        abstract:
        """

        Record your Xcode simulator and convert it to GIF, MP4 or Mov
        """,
        discussion:
        """
        \(appName) \(version)
        
        Created by Wendy Liga
        Learn more https://github.com/wendyliga/mimiq
        """,
        subcommands: [
            Record.self,
            List.self,
            Version.self,
            Cache.self,
        ],
        defaultSubcommand: Record.self
    )
}

Main.main()
