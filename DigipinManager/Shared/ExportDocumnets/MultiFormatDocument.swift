//
//  MultiFormatDocument.swift
//  DigipinManager
//
//  Created by Rishi Singh on 12/08/25.
//

import SwiftUI
import UniformTypeIdentifiers


enum DocumentExportError: Error {
    case encodingFailed(Error)
    case invalidUTF8
}

protocol FileEncodable {
    func encodeData(for type: UTType) throws -> Data
}

struct MultiFormatDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json, .commaSeparatedText]
    static var writableContentTypes: [UTType] = [.json, .commaSeparatedText]

    var data: Data
    var contentType: UTType

    init(data: Data, type: UTType) {
        self.data = data
        self.contentType = type
    }

    init<T: FileEncodable>(object: T, type: UTType) throws {
        self.data = try object.encodeData(for: type)
        self.contentType = type
    }

    init(configuration: ReadConfiguration) throws {
        guard let type = configuration.contentType as UTType?,
              let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
        self.contentType = type
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

extension String: FileEncodable {
    func encodeData(for type: UTType) throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw DocumentExportError.invalidUTF8
        }
        return data
    }
}

protocol CSVEncodable: FileEncodable {
    func toCSV() throws -> String
}

extension CSVEncodable {
    func encodeData(for type: UTType) throws -> Data {
        guard type == .commaSeparatedText else {
            throw CocoaError(.fileWriteUnknown)
        }
        return try toCSV().data(using: .utf8) ?? { throw DocumentExportError.invalidUTF8 }()
    }
}

protocol JSONEncodable: Encodable, FileEncodable {}

extension JSONEncodable {
    func encodeData(for type: UTType) throws -> Data {
        guard type == .json else {
            throw CocoaError(.fileWriteUnknown)
        }
        do {
            return try JSONEncoder()
                .encode(self)
        } catch {
            throw DocumentExportError.encodingFailed(error)
        }
    }
}
