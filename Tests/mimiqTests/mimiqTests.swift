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

import XCTest
import class Foundation.Bundle

final class mimiqTests: XCTestCase {
    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
    
    func shellProcess(args: [String]) throws -> String? {
        guard #available(macOS 10.13, *) else {
            return nil
        }
        
        let fooBinary = productsDirectory.appendingPathComponent("mimiq")

        let process = Process()
        process.executableURL = fooBinary
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        return output
    }
    
    func test_record_noHomebrewInstalled() throws {
        let expected = "💥 Missing Homebrew, please install Homebrew, for more visit https://brew.sh\n"
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "noHomebrew"]), expected)
    }
    
    func test_record_noFFMpegInstalled() throws {
        let expected = "💥 Missing FFMpeg, please install mpeg, by executing `brew install ffmpeg`\n"
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "noFFMpeg"]), expected)
    }
    
    func test_record_noSimulator() throws {
        let expected = "💥 No Available Simulator to mimiq\n"
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "noSimulator"]), expected)
    }
    
    func test_record_failRecord() throws {
        let expected = "💥 Record Failed, Please Try Again\n"
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "failRecord"]), expected)
    }
    
    func test_record_failMakeGIF() throws {
        let expected = [
            "⚙️  Creating GIF...",
            "💥 Failed on Creating GIF, Please Try Again",
            ""]
            .joined(separator: "\n")
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "failMakeGIF"]), expected)
    }
    
    func test_record_success() throws {
        let expected = [
            "⚙️  Creating GIF...",
            "✅ Grab your GIF at ~/Desktop/mimiq.gif",
            ""]
            .joined(separator: "\n")
        
        XCTAssertEqual(try shellProcess(args: ["--mode", "success"]), expected)
    }
    
    func test_checkVersion() throws {
        let expected = "current version 0.4.1\n"
        
        XCTAssertEqual(try shellProcess(args: ["version"]), expected)
    }
    
    func test_listQuality() throws {
        let expected = """
        Available Quality
        - low
        - medium
        - high

        """
        
        XCTAssertEqual(try shellProcess(args: ["quality"]), expected)
    }
    
    func test_listSimulator_exist() throws {
        let expected = [
            "Available Simulator to mimiq: ",
            "✅ 00000000-0000-0000-0000-000000000000 Mimiq Simulator",
            "✅ 11111111-1111-1111-1111-111111111111 Mimiq Simulator #2",
            ""]
            .joined(separator: "\n")
        
        XCTAssertEqual(try shellProcess(args: ["list", "--mode", "available"]), expected)
    }
    
    func test_listSimulator_notExist() throws {
        let expected = "💥 No Available Simulator to mimiq\n"
        
        XCTAssertEqual(try shellProcess(args: ["list", "--mode", "none"]), expected)
    }
    
    func test_listSimulatorJSON_exist() throws {
        let expected = "[{\"name\":\"Mimiq Simulator\",\"udid\":\"00000000-0000-0000-0000-000000000000\"},{\"name\":\"Mimiq Simulator #2\",\"udid\":\"11111111-1111-1111-1111-111111111111\"}]\n"
        
        XCTAssertEqual(try shellProcess(args: ["list", "--mode", "available", "--json"]), expected)
    }
    
    func test_listSimulatorJSON_notExist() throws {
        let expected = "[]\n"
        
        XCTAssertEqual(try shellProcess(args: ["list", "--mode", "none", "--json"]), expected)
    }

    static var allTests = [
        ("test_record_noHomebrewInstalled", test_record_noHomebrewInstalled),
        ("test_record_noFFMpegInstalled", test_record_noFFMpegInstalled),
        ("test_record_noSimulator", test_record_noSimulator),
        ("test_record_failRecord", test_record_failRecord),
        ("test_record_failMakeGIF", test_record_failMakeGIF),
        ("test_record_success", test_record_success),
        ("test_checkVersion", test_checkVersion),
        ("test_listSimulator_exist", test_listSimulator_exist),
        ("test_listSimulator_notExist", test_listSimulator_notExist),
        ("test_listSimulatorJSON_exist", test_listSimulatorJSON_exist),
        ("test_listSimulatorJSON_notExist", test_listSimulatorJSON_notExist)
    ]
}
