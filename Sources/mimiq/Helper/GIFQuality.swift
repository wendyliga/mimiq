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

enum GIFQuality: String, ExpressibleByArgument, CaseIterable {
    case low
    case medium
    case high
    
    /**
     generate gif command based on quality
     
     - Parameters:
        - source: where source target path
        - target: where gif will be generated
     */
    func gifCommand(source: String, target: String) -> String {
        switch self {
        case .low:
            let setPallete = #"palette="/tmp/palette.png""#
            let configureFilter = #"filters="fps=5,scale=320:-1:flags=lanczos""#
            let slicingVideo = #"ffmpeg -nostdin -v warning -i \#(source) -vf "$filters,palettegen=stats_mode=diff" -y $palette"#
            let createGIF = #"ffmpeg -nostdin -i \#(source) -i $palette -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y \#(target)"#
            
            return [setPallete, configureFilter , slicingVideo, createGIF].joined(separator: ";")
        case .medium:
            let setPallete = #"palette="/tmp/palette.png""#
            let configureFilter = #"filters="fps=15,scale=320:-1:flags=lanczos""#
            let slicingVideo = #"ffmpeg -nostdin -v warning -i \#(source) -vf "$filters,palettegen=stats_mode=diff" -y $palette"#
            let createGIF = #"ffmpeg -nostdin -i \#(source) -i $palette -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y \#(target)"#
            
            return [setPallete, configureFilter , slicingVideo, createGIF].joined(separator: ";")
        case .high:
            let setPallete = #"palette="/tmp/palette.png""#
            let configureFilter = #"filters="fps=30,scale=320:-1:flags=lanczos""#
            let slicingVideo = #"ffmpeg -nostdin -v warning -i \#(source) -vf "$filters,palettegen=stats_mode=diff" -y $palette"#
            let createGIF = #"ffmpeg -nostdin -i \#(source) -i $palette -lavfi "$filters,paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y \#(target)"#
            
            return [setPallete, configureFilter , slicingVideo, createGIF].joined(separator: ";")
        }
    }
}
