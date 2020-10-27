//
//  Variants
//
//  Copyright (c) Backbase B.V. - https://www.backbase.com
//  Created by Arthur Alves
//

import Foundation
import PathKit
import ArgumentParser

struct Initializer: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Generate spec file - variants.yml"
    )
    
    // --------------
    // MARK: Configuration Properties
    
    @Option(name: .shortAndLong, help: "'ios' or 'android'")
    var platform: Platform = .unknown
    
    @Flag(name: .shortAndLong, help: "Log tech details for nerds")
    var verbose = false

    mutating func run() throws {
        let logger = Logger(verbose: verbose)
        logger.logSection("$ ", item: "variants init", color: .ios)
        
        // Platform auto detection
        do {
            if platform == .unknown {
                platform = try Platform.detectPlatform()
            }
        } catch let error as PlatformScanError {
            throw error
        }
        
        // 'Templates' folder integrity check
        let templateManager = TemplatesManager()
        guard let path = templateManager.firstFoundTemplateDirectory() else {
            var expectedLocation = templateManager.templateDirectories.joined(separator: ", ")
            if #available(macOS 10.15, *) {
                expectedLocation = ListFormatter.localizedString(byJoining: templateManager.templateDirectories)
            }
            throw RuntimeError("'Templates' folder not found on \(expectedLocation)")
        }

        // Generate 'variants.yml' spec
        do {
            try VariantSpecFactory().generateSpec(path: path, platform: platform)
        } catch {
            throw RuntimeError.unableToInitializeVariants
        }
    }
}
