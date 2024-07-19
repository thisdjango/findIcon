//
//  IconModel.swift
//  findIcon
//
//  Created by Diana Tsarkova on 07.07.2024.
//

import Foundation

struct IconModel: Codable {

    var iconId: Int?
    var previewURL: String?
    var iconURL: String?
    var maxSize: String?
    var tags: String
    var isFav: Bool {
        get {
            guard let id = iconId else { return false }
            return UserDefaults.standard.bool(forKey: String(id))
        } 
        set {
            guard let id = iconId else { return }
            UserDefaults.standard.setValue(newValue, forKey: String(id))
        }
    }

    init(id: Int? = nil, previewURL: String? = nil, iconURL: String? = nil, maxSize: String? = nil, tags: String) {
        self.iconId = id
        self.previewURL = previewURL
        self.iconURL = iconURL
        self.maxSize = maxSize
        self.tags = tags
    }

}
