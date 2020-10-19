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
import mimiq_core

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
    
    func shellProcess(args: [String]) throws -> Shell.Result {
        /// remove `file://` from foo Binary url path
        var fooBinary = productsDirectory.appendingPathComponent("mimiq").absoluteString
        fooBinary.removeFirst(7)
        
        return Shell.execute(launchPath: fooBinary, arguments: args, executingWithBash: false)
    }
    
    func test_record_noHomebrewInstalled() throws {
        let expected = "💥 Missing Homebrew, please install Homebrew, for more visit https://brew.sh\n"
        let shellResult = try shellProcess(args: ["record", "--mode", "noHomebrew"])
        
        XCTAssertEqual(shellResult.errorOuput?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 1)
    }
    
    func test_record_noFFMpegInstalled() throws {
        let expected = "💥 Missing FFMpeg, please install mpeg, by executing `brew install ffmpeg`\n"
        let shellResult = try shellProcess(args: ["--mode", "noFFMpeg"])
        
        XCTAssertEqual(shellResult.errorOuput?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 1)
    }
    
    func test_record_noSimulator() throws {
        let expected = "💥 No Available Simulator to mimiq\n"
        let shellResult = try shellProcess(args: ["--mode", "noSimulator"])
        
        XCTAssertEqual(shellResult.errorOuput?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 1)
    }
    
    func test_record_failRecord() throws {
        let expected = "💥 Record Failed, Please Try Again\n"
        let shellResult = try shellProcess(args: ["--mode", "failRecord"])
        
        XCTAssertEqual(shellResult.errorOuput?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 1)
    }
    
    func test_record_failMakeGIF() throws {
        let output = "⚙️ Creating output...\n"
        let errorOutput = "💥 Failed on Creating output, Please Try Again\n"
        let shellResult = try shellProcess(args: ["--mode", "failMakeGIF"])
        
        XCTAssertEqual(shellResult.output?.rawValue, output)
        XCTAssertEqual(shellResult.errorOuput?.rawValue, errorOutput)
        XCTAssertEqual(shellResult.status, 1)
    }
    
    func test_record_success() throws {
        let expected = [
            "⚙️ Creating output...",
            "✅ Grab your output at ~/Desktop/mimiq.gif",
            ""]
            .joined(separator: "\n")
        let shellResult = try shellProcess(args: ["--mode", "success"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_checkVersion() throws {
        let expected = "current version 0.5.0\n"
        let shellResult = try shellProcess(args: ["version"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listQuality() throws {
        let expected = """
        Available Quality
        - low
        - medium
        - high

        """
        let shellResult = try shellProcess(args: ["quality"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listOutputType() throws {
        let expected = """
        Available Output Type
        - gif
        - mov
        - mp4

        """
        let shellResult = try shellProcess(args: ["output-type"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listSimulator_exist() throws {
        let expected = [
            "Available Simulator to mimiq: ",
            "✅ 00000000-0000-0000-0000-000000000000 Mimiq Simulator",
            "✅ 11111111-1111-1111-1111-111111111111 Mimiq Simulator #2",
            ""]
            .joined(separator: "\n")
        
        let shellResult = try shellProcess(args: ["list", "--mode", "available"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listSimulator_notExist() throws {
        let expected = "💥 No Available Simulator to mimiq\n"
        let shellResult = try shellProcess(args: ["list", "--mode", "none"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listSimulatorJSON_exist() throws {
        let expected = "[{\"name\":\"Mimiq Simulator\",\"udid\":\"00000000-0000-0000-0000-000000000000\"},{\"name\":\"Mimiq Simulator #2\",\"udid\":\"11111111-1111-1111-1111-111111111111\"}]\n"
        let shellResult = try shellProcess(args: ["list", "--mode", "available", "--json"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
    
    func test_listSimulatorJSON_notExist() throws {
        let expected = "[]\n"
        let shellResult = try shellProcess(args: ["list", "--mode", "none", "--json"])
        
        XCTAssertEqual(shellResult.output?.rawValue, expected)
        XCTAssertEqual(shellResult.status, 0)
    }
}
