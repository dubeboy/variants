//
//  Variants
//
//  Copyright (c) Backbase B.V. - https://www.backbase.com
//  Created by Giuseppe Deraco
//

import Foundation
import PathKit
import Stencil

class GradleScriptFactory {
    init(templatePath: Path? = try? TemplateDirectory().path) {
        self.templatePath = templatePath
    }
    
    /// Create `gradleScripts/variants.gradle` file inside project's path
    /// - Parameters:
    ///   - configuration: Android configuration from `variants.yml`
    ///   - variant: Desired project variant.
    func createScript(with configuration: AndroidConfiguration, variant: AndroidVariant) throws {
        let variantsScriptPath = try Path(configuration.path).safeJoin(path: Path("gradleScripts/"))
        if !variantsScriptPath.exists {
            try variantsScriptPath.mkpath()
        }
        guard let data = try render(with: configuration, variant: variant) else { return }
        try write(data, using: variantsScriptPath)
    }
    
    func render(with configuration: AndroidConfiguration, variant: AndroidVariant) throws -> Data? {
        var context = [
            "variant": variant,
            "configuration": configuration
        ] as [String : Any]

        if let variantProperties = variant.custom?.filter({ $0.destination == .project }) {
            context["variant_properties"] = variantProperties
        }
        
        if let globalProperties = configuration.custom?.filter({ $0.destination == .project }) {
            context["global_properties"] = globalProperties
        }
        
        guard
            let path = templatePath,
            let androidTemplatePath = try? path.safeJoin(path: Path("android/"))
        else { return nil }
        let environment = Environment(loader: FileSystemLoader(paths: [androidTemplatePath.absolute()]))
        let rendered = try environment.renderTemplate(name: StaticPath.Template.variantsScriptFileName,
                                                      context: context)
        
        // Replace multiple empty lines by one only
        let lines = rendered.split(whereSeparator: \.isNewline)
        let content = lines.joined(separator: "\n")
        
        print(content)
        return Data(content.utf8)
    }
    
    func write(_ data: Data, using gradleScriptFolder: Path) throws {
            if gradleScriptFolder.isDirectory, gradleScriptFolder.exists {
                let fastlaneParametersFile = Path(gradleScriptFolder.string+StaticPath
                                                    .Gradle.variantsScriptFileName)
                
                // Only proceed to write to file if such doesn't yet exist
                // Or does exist and 'isWritable'
                guard !fastlaneParametersFile.exists
                        || fastlaneParametersFile.isWritable else {
                    throw TemplateDoesNotExist(templateNames: [gradleScriptFolder.string])
                }
                
                // Write to file
                try fastlaneParametersFile.write(data)
            } else {
                throw TemplateDoesNotExist(templateNames: [gradleScriptFolder.string])
            }
    }
    
    private let templatePath: Path?
}
