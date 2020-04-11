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
