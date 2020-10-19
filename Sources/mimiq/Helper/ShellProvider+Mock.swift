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
    
    func recordSimulator(
        target: Simulator,
        movTarget: String,
        logger: Logger?,
        completion: @escaping (Shell.Result) -> Void
    ) {
        completion((0, nil, nil))
    }
    
    func generateOutput(
        _ type: OutputType,
        movSource: String,
        outputTarget: String,
        quality: GIFQuality,
        customFFMpegPath: String?,
        logger: Logger?
    ) -> Shell.Result {
        (0, nil, nil)
    }
    
    func list(
        at path: String,
        withFolder isFolderIncluded: Bool,
        isRecursive: Bool
    ) -> Result<[Explorable], Error> {
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
        return false
    }
}

final class NoFFMpegShellProvider: ShellProvider {
    var isFFMpegInstalled: Bool {
        false
    }
}

final class FailedRecordShellProvider: ShellProvider {
    func recordSimulator(
        target: Simulator,
        movTarget: String,
        logger: Logger?,
        completion: @escaping (Shell.Result) -> Void
    ) {
        completion((1, nil, "Failed to create mov file"))
    }
}

final class FailedConvertingGIFShellProvider: ShellProvider {
    func generateOutput(
        _ type: OutputType,
        movSource: String,
        outputTarget: String,
        quality: GIFQuality,
        customFFMpegPath: String?,
        logger: Logger?
    ) -> Shell.Result {
        (1, nil, "Failed to convert MOV to GIF")
    }
}

final class SuccessShellProvider: ShellProvider {}
#endif
