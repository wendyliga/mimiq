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

import Foundation

// MARK: - JSONDecoder Extension

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

// MARK: - String Extension

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
