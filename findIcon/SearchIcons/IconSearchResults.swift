//
//  IconSearchResults.swift
//  findIcon
//
//  Created by Diana Tsarkova on 04.07.2024.
//

//   let iconSearchResults = try? JSONDecoder().decode(IconSearchResults.self, from: jsonData)

import Foundation

// MARK: - IconSearchResults
struct IconSearchResults: Codable {
    let totalCount: Int
    let icons: [Icon]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case icons
    }
}

// MARK: - Icon
struct Icon: Codable {
    let iconID: Int
    let tags: [String]
    let rasterSizes: [RasterSize]

    enum CodingKeys: String, CodingKey {
        case iconID = "icon_id"
        case tags
        case rasterSizes = "raster_sizes"
    }

    func toIconModel() -> IconModel {
        var maxSize: String?
        if let last = rasterSizes.last {
            maxSize = "\(last.sizeWidth) x \(last.sizeHeight)"
        }
        return IconModel(
            id: iconID,
            previewURL: rasterSizes.first?.formats.first?.previewURL,
            iconURL: rasterSizes.last?.formats.first?.downloadURL,
            maxSize: maxSize,
            tags: tags.joined(separator: ", ")
        )
    }
}

// MARK: - RasterSize
struct RasterSize: Codable {
    let formats: [FormatElement]
    let size, sizeWidth, sizeHeight: Int

    enum CodingKeys: String, CodingKey {
        case formats, size
        case sizeWidth = "size_width"
        case sizeHeight = "size_height"
    }
}

// MARK: - FormatElement
struct FormatElement: Codable {
    let format: String
    let previewURL: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case format
        case previewURL = "preview_url"
        case downloadURL = "download_url"
    }
}
