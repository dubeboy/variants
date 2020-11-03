//
//  Variants
//
//  Copyright (c) Backbase B.V. - https://www.backbase.com
//  Created by Arthur Alves
//

import XCTest
import PathKit
@testable import VariantsCore

let parameters = [
    CustomProperty(name: "sample", value: "sample-value", destination: .envVar),
    CustomProperty(name: "sample-2", value: "sample-2-value", destination: .fastlane),
    CustomProperty(name: "sample-3", value: "sample-3-value", destination: .project),
    CustomProperty(name: "sample-4", value: "sample-4-value", destination: .fastlane),
    CustomProperty(name: "sample-5", value: "sample-5-value", destination: .fastlane)
]

let correctOutput =
    """
    # Generated by Variants
    VARIANTS_PARAMS = {
        sample-2: \"sample-2-value\",
        sample-4: \"sample-4-value\",
        sample-5: \"sample-5-value\",
    }.freeze
    """

class FastlaneParametersFactoryTests: XCTestCase {
    func testRender_correctData() {
        guard
            let templateFilePath = Bundle(for: type(of: self))
                .path(forResource: "Resources/variants_params_template", ofType: "rb"),
            let templateFileContent = try? String(contentsOfFile: templateFilePath,
                                                  encoding: .utf8)
        else { return }
        
        // Assset we are able to write the template's content to a temporary
        // template in `private/tmp/`, to be used as `Path` from this test target.
        // Without this Path, `FastlaneParametersFactory` can't be tested as it
        // depends on `Stencil.FileSystemLoader` to load the template.
        let temporaryTemplatePath = Path("variants_params_template.rb")
        XCTAssertNoThrow(try temporaryTemplatePath.write(templateFileContent))
        
        let fastlaneParameters = parameters.filter { $0.destination == .fastlane }
        let factory = FastlaneParametersFactory(path: Path("./"))
        
        XCTAssertNoThrow(try factory.render(parameters: fastlaneParameters))
        XCTAssertNotNil(try factory.render(parameters: fastlaneParameters))
        
        let renderedData = try! factory.render(parameters: fastlaneParameters)!
        XCTAssertEqual(String(data: renderedData, encoding: .utf8), correctOutput)
    }
    
    func testFileWrite_correctOutput() {
        let basePath = Path("")
        let fastlaneParameters = Path("fastlane/parameters")
        if fastlaneParameters.exists {
            try! fastlaneParameters.delete()
        }
        XCTAssertNoThrow(try fastlaneParameters.mkpath())
        
        let factory = FastlaneParametersFactory(path: basePath)
        XCTAssertNoThrow(try factory.write(Data(correctOutput.utf8), using: fastlaneParameters))
        
        let fastlaneParametersFile = Path(fastlaneParameters.string+"/variants_params.rb")
        XCTAssertEqual(try fastlaneParametersFile.read(), correctOutput)
    }
}
