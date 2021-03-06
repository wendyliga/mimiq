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
import ConsoleIO
import Logging
import mimiq_core

// MARK: - Shell Provider

/**
 Shell Operation Abstraction
 */
protocol ShellProvider {
    var isHomebrewInstalled: Bool { get }
    var isFFMpegInstalled: Bool { get }
    var availableSimulators: [Simulator] { get }
    func recordSimulator(target: Simulator, movTarget: String, logger: Logger?, completion: @escaping (Shell.Result) -> Void)
    func generateOutput(_ type: OutputType, movSource: String, outputTarget: String, quality: GIFQuality, customFFMpegPath: String?, logger: Logger?) -> Shell.Result
    func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error>
}

final class DefaultShellProvider: ShellProvider {
    static let shared = DefaultShellProvider()
    
    var isHomebrewInstalled: Bool {
        Shell.execute(arguments: [#"! homebrew_loc="$(type -p "brew")" || [[ -z $homebrew_loc ]];"#]).status == 1
    }
    
    var isFFMpegInstalled: Bool {
        Shell.execute(arguments: [#"! ffmpeg_loc="$(type -p "ffmpeg")" || [[ -z $ffmpeg_loc ]];"#]).status == 1
    }
    
    var availableSimulators: [Simulator] {
        let simulatorRuntimeListShellExecution = Shell.execute(arguments: ["xcrun simctl list -v runtimes --json"])
        
        guard
            simulatorRuntimeListShellExecution.status == 0,
            let runtimeListRawData = simulatorRuntimeListShellExecution.output?.rawValue.data(using: .utf8),
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

        let simulatorListShellExecution = Shell.execute(arguments: ["xcrun simctl list -v devices booted --json"])
        
        guard
            simulatorListShellExecution.status == 0,
            let simulatorListRawData = simulatorListShellExecution.output?.rawValue.data(using: .utf8),
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
    
    func recordSimulator(
        target: Simulator,
        movTarget: String,
        logger: Logger?,
        completion: @escaping (Shell.Result) -> Void
    ) {
        let recordCommand = "xcrun simctl io \(target.udid.uuidString) recordVideo -f \(movTarget)"
        let recordMessage = "🔨 Recording Simulator \(target.name) with UDID \(target.udid)... Press Enter to Stop.)"
        
        logger?.debug(#"start recording with command "\#(recordCommand)""#)
        
        Shell.mustInterupt(arguments: [recordCommand], message: recordMessage, logger: logger, completion: completion)
    }
    
    func generateOutput(
        _ type: OutputType,
        movSource: String,
        outputTarget: String,
        quality: GIFQuality,
        customFFMpegPath: String?,
        logger: Logger?
    ) -> Shell.Result {
        var command = [String]()
        
        if let customFFMpegpath = customFFMpegPath {
            // register path where custom ffmpeg is located
            command.append("export PATH=$PATH:\(customFFMpegpath)")
        }
        
        switch type {
        case .gif:
            logger?.info("Output will be created on \(outputTarget), with \(quality) quality")
            command.append(quality.ffmpegCommand(source: movSource, target: outputTarget))
        case .mov, .mp4:
            logger?.info("Output will be created on \(outputTarget)")
            command.append(type.ffmpegCommand(source: movSource, target: outputTarget))
        }
        
        logger?.debug(#"executing "\#(command)""#)
        return Shell.execute(arguments: [command.joined(separator: ";")])
    }
    
    func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        Explorer.default.list(at: path, withFolder: isFolderIncluded, isRecursive: isRecursive)
    }
}
