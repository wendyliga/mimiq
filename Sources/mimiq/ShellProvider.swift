import Explorer
import Foundation
import ConsoleIO

struct Runtime: Decodable {
    let identifier: String
}

struct Simulator: Codable {
    let udid: UUID
    let name: String
}

// MARK: - Shell Command

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
    }
    
    input(message, defaultValue: "", afterValidation: { _ in
        print("⚙️  Stopping...")
        Log.default.write("stopping simulator recording process")
        task.interrupt()
    })
    
    task.terminationHandler = { process in
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOuput = String(data: errorData, encoding: String.Encoding.utf8)
        
        completion((status: task.terminationStatus, output: output, errorOuput: errorOuput))
    }
}

// MARK: - Shell Provider

/**
 Shell Operation Abstraction
 */
protocol ShellProvider {
    var isHomebrewInstalled: Bool { get }
    var isFFMpegInstalled: Bool { get }
    var availableSimulators: [Simulator] { get }
    func recordSimulator(target: Simulator, movTarget: String, printOutLog: Bool, completion: @escaping (ShellResult) -> Void)
    func convertMovToGif(movSource: String, gifTarget: String, customFFMpegPath: String?, printOutLog: Bool) -> ShellResult
    func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error>
}

final class DefaultShellProvider: ShellProvider {
    static let shared = DefaultShellProvider()
    
    var isHomebrewInstalled: Bool {
        shell(arguments: [#"! homebrew_loc="$(type -p "brew")" || [[ -z $homebrew_loc ]];"#]).status == 1
    }
    
    var isFFMpegInstalled: Bool {
        shell(arguments: [#"! ffmpeg_loc="$(type -p "ffmpeg")" || [[ -z $ffmpeg_loc ]];"#]).status == 1
    }
    
    var availableSimulators: [Simulator] {
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
    
    func recordSimulator(target: Simulator, movTarget: String, printOutLog: Bool, completion: @escaping (ShellResult) -> Void) {
        let recordCommand = "xcrun simctl io \(target.udid.uuidString) recordVideo -f \(movTarget)"
        let recordMessage = "🔨 Recording Simulator \(target.name) with UDID \(target.udid)... Press Enter to Stop.)"
        
        Log.default.write(#"start recording with command "\#(recordCommand)""#, printOut: printOutLog)
        
        mustInteruptShell(arguments: [recordCommand], message: recordMessage, completion: completion)
    }
    
    func convertMovToGif(movSource: String, gifTarget: String, customFFMpegPath: String?, printOutLog: Bool) -> ShellResult {
        Log.default.write("GIF will be created on \(gifTarget)", printOut: printOutLog)
        
        var command = [String]()
        
        let setPallete = #"palette="/tmp/palette.png""#
        let configureFilter = #"filters="fps=15,scale=320:-1:flags=lanczos""#
        let slicingVideo = #"ffmpeg -nostdin -v warning -i \#(movSource) -vf "$filters,palettegen=stats_mode=diff" -y $palette"#
        let createGIF = #"ffmpeg -nostdin -i \#(movSource) -i $palette -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y \#(gifTarget)"#
        let generateGIFCommand = [setPallete, configureFilter , slicingVideo, createGIF].joined(separator: ";")
        
        if let customFFMpegpath = customFFMpegPath {
            // register path where custom ffmpeg is located
            command.append("export PATH=$PATH:\(customFFMpegpath)")
        }
        
        command.append(generateGIFCommand)
        
        Log.default.write(#"executing ffmpeg with command "\#(command)""#, printOut: printOutLog)
        return shell(arguments: [command.joined(separator: ";")])
    }
    
    func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        Explorer.default.list(at: path, withFolder: isFolderIncluded, isRecursive: isRecursive)
    }
}

// MARK: - Mock Shell Provider

#if DEBUG
let dummySimulator: [Simulator] = [
    Simulator(udid: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "Mimiq Simulator"),
    Simulator(udid: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Mimiq Simulator #2")
]

extension ShellProvider {
    var isHomebrewInstalled: Bool {
        true
    }
    
    var isFFMpegInstalled: Bool {
        true
    }
    
    var availableSimulators: [Simulator] {
        dummySimulator
    }
    
    func recordSimulator(target: Simulator, movTarget: String, printOutLog: Bool) -> ShellResult {
        (0, nil, nil)
    }
    
    func convertMovToGif(movSource: String, gifTarget: String, printOutLog: Bool) -> ShellResult {
        (0, nil, nil)
    }
    
    func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        .success([])
    }
}

final class AvailableSimulatorShellProvider: ShellProvider {
    var availableSimulators: [Simulator] {
        dummySimulator
    }
}

final class NoneSimulatorShellProvider: ShellProvider {
    var availableSimulators: [Simulator] {
        []
    }
}

final class NoHomebrewShellProvider: ShellProvider {
    var isHomebrewInstalled: Bool {
        false
    }
}

final class NoFFMpegShellProvider: ShellProvider {
    var isFFMpegInstalled: Bool {
        false
    }
}

final class FailedRecordShellProvider: ShellProvider {
    func recordSimulator(target: Simulator, movTarget: String, printOutLog: Bool) -> ShellResult {
        (1, nil, "Failed to create mov file")
    }
}

final class FailedConvertingGIFShellProvider: ShellProvider {
    func convertMovToGif(movSource: String, gifTarget: String, printOutLog: Bool) -> ShellResult {
        (1, nil, "Failed to convert MOV to GIF")
    }
}

final class SuccessShellProvider: ShellProvider {}
#endif
