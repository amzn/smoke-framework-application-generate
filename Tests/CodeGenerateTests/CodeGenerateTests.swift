import XCTest
@testable import SmokeFrameworkApplicationGenerateCommand
class CodeGenerateTests: XCTestCase {
    func testExample() {
        print("This is an example test")
    }

    func executionPlanServiceGenerate() throws {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/ExecutionPlanService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/ExecutionPlanService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func contentIngressServiceGenerate() {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/ContentIngressService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/ContentIngressService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func playbackAssetsServiceGenerate() {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/PlaybackAssetsService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/PlaybackAssetsService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func playbackObjectProcessorServiceGenerate() {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/PlaybackObjectProcessorService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectProcessorService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func playbackObjectServiceGenerate() {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/PlaybackObjectService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/PlaybackObjectService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }
    
    func targetPublishingServiceGenerate() {
        let swaggerCommand = ["base-file-path /Users/mndzup/Desktop/Service_Swagger/TargetPublishingService", "swagger-version 2"]
        SmokeFrameworkApplicationGenerateCommand.main(swaggerCommand)
        let openAPICommand = ["base-file-path /Users/mndzup/Desktop/Service_OpenAPI/TargetPublishingService", "swagger-version 3"]
        SmokeFrameworkApplicationGenerateCommand.main(openAPICommand)
    }

    static var allTests = [
        ("testExample", testExample),
        ("executionPlanServiceGenerate", executionPlanServiceGenerate),
        ("contentIngressServiceGenerate", contentIngressServiceGenerate),
        ("playbackAssetsServiceGenerate", playbackAssetsServiceGenerate),
        ("playbackObjectProcessorServiceGenerate", playbackObjectProcessorServiceGenerate),
        ("playbackObjectServiceGenerate", playbackObjectServiceGenerate),
        ("targetPublishingServiceGenerate", targetPublishingServiceGenerate)
    ]
}
