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

enum OutputType: String, CaseIterable, ExpressibleByArgument {
    case gif
    case mov
    case mp4
    
    /**
     File extension
     */
    var fileExtension: String {
        switch self {
        case .gif:
            return "gif"
        case .mov:
            return "mov"
        case .mp4:
            return "mp4"
        }
    }
    
    /**
     generate gif command based on quality
     
     - Parameters:
        - source: where source target path
        - target: where output will be generated
     */
    func ffmpegCommand(source: String, target: String) -> String {
        switch self {
        case .gif:
            /// ffmpeg command will use `GIFQuality` one.
            return ""
        case .mov:
            /// no ffmpeg process
            return "cp \(source) \(target)"
        case .mp4:
            /// provide user to change video and audio codec ?
            return "ffmpeg -i \(source) -vcodec h264 -acodec mp2 \(target)"
        }
    }
}
