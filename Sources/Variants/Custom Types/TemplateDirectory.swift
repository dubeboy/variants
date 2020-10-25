//
// Created by Balazs Toth on 25/10/2020.
// Copyright © 2020. All rights reserved.
// 

import Foundation
import PathKit

struct TemplateDirectory {
    var path: Path

    // MARK: - Init methods

    init(
        directories: [String] = [
            "/usr/local/lib/variants/templates",
            "./Templates"
        ]
    ) throws {
        let firstDirectory = directories
            .map(Path.init(stringLiteral:))
            .first(where: \.exists)

        guard let path = firstDirectory else {
            let dirs = directories.joined(separator: ' or ')
            throw RuntimeError("❌ Templates folder not found in \(dirs)")
        }

        self.path = path
    }

    init(path: Path) {
        self.path = path
    }
}
