import XCTest
@testable import SmokeFrameworkApplicationGenerateCommand
class CodeGenerateTests: XCTestCase {

    func testExecutionPlanServiceGenerate() {
        let swaggerCommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_Swagger/ExecutionPlanService", "--swagger-version", "2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_OpenAPI/ExecutionPlanService", "--swagger-version", "3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func testContentIngressServiceGenerate() {
        let swaggerCommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_Swagger/ContentIngressService", "--swagger-version", "2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_OpenAPI/ContentIngressService", "--swagger-version", "3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func testPlaybackAssetsServiceGenerate() {
        let swaggerCommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_Swagger/PlaybackAssetsService", "--swagger-version", "2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_OpenAPI/PlaybackAssetsService", "--swagger-version", "3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func testPlaybackObjectProcessorServiceGenerate() {
        let swaggerCommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_Swagger/PlaybackObjectProcessorService", "--swagger-version", "2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path", "/Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectProcessorService", "--swagger-version", "3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func testPlaybackObjectServiceGenerate() {
        let swaggerCommand = ["--base-file-path /Users/mndzup/Desktop/Service_Swagger/PlaybackObjectService", "--swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path /Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectService", "--swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func testTargetPublishingServiceGenerate() {
        let swaggerCommand = ["--base-file-path /Users/mndzup/Desktop/Service_Swagger/TargetPublishingService", "--swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["--base-file-path /Users/mndzup/Desktop/Service_OpenAPI/TargetPublishingService", "--swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }

    static var allTests = [
        ("testExecutionPlanServiceGenerate", testExecutionPlanServiceGenerate),
        ("testContentIngressServiceGenerate", testContentIngressServiceGenerate),
        ("testPlaybackAssetsServiceGenerate", testPlaybackAssetsServiceGenerate),
        ("testPlaybackObjectProcessorServiceGenerate", testPlaybackObjectProcessorServiceGenerate),
        ("testPlaybackObjectServiceGenerate", testPlaybackObjectServiceGenerate),
        ("testTargetPublishingServiceGenerate", testTargetPublishingServiceGenerate)
    ]
}
