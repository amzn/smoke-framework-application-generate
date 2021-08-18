import XCTest
@testable import SmokeFrameworkApplicationGenerateCommand
class CodeGenerateTests: XCTestCase {

    func testExecutionPlanServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/ExecutionPlanService"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/ExecutionPlanService"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }
    
    func testContentIngressServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/ContentIngressService"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/ContentIngressService"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }
    
    func testPlaybackAssetsServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/PlaybackAssetsLambda"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/PlaybackAssetsLambda"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }
    
    func testPlaybackObjectProcessorServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/PlaybackObjectProcessorService"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectProcessorService"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }
    
    func testPlaybackObjectsServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/PlaybackObjectsService"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectsService"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }
    
    func testTargetPublishingServiceGenerate() {
        let swaggerFilePath = "/Users/mndzup/Desktop/Service_Swagger/TargetPublishingService"
        let openAPIFilePath = "/Users/mndzup/Desktop/Service_OpenAPI/TargetPublishingService"
        let swaggerCommand = ["--base-file-path", swaggerFilePath, "--swagger-version", "2"]
        let openAPICommand = ["--base-file-path", openAPIFilePath, "--swagger-version", "3"]
        let fileManager = FileManager()

        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
        
        let pass = fileManager.contentsEqual(atPath: swaggerFilePath + "/Sources/", andPath: openAPIFilePath + "/Sources/")
        XCTAssertTrue(pass)
    }

    static var allTests = [
        ("testExecutionPlanServiceGenerate", testExecutionPlanServiceGenerate),
        ("testContentIngressServiceGenerate", testContentIngressServiceGenerate),
        ("testPlaybackAssetsServiceGenerate", testPlaybackAssetsServiceGenerate),
        ("testPlaybackObjectProcessorServiceGenerate", testPlaybackObjectProcessorServiceGenerate),
        ("testPlaybackObjectServiceGenerate", testPlaybackObjectsServiceGenerate),
        ("testTargetPublishingServiceGenerate", testTargetPublishingServiceGenerate)
    ]
}
