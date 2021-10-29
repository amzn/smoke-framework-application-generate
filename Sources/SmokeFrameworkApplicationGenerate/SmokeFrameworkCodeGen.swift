//
//  SmokeFrameworkCodeGen.swift
//  SmokeFrameworkApplicationGenerate
//

import SmokeFrameworkCodeGeneration
import ServiceModelEntities
import ServiceModelCodeGeneration

struct AsyncAwaitCodeGenParameters: Codable {
    let clientAPIs: CodeGenFeatureStatus
    // Allow server async/await support when XCTest supports it
    // https://github.com/apple/swift-corelibs-xctest/pull/331
    //let asyncOperationStubs: AsyncAwaitSupport

    static var `default`: AsyncAwaitCodeGenParameters {
        return AsyncAwaitCodeGenParameters(clientAPIs: .enabled)
    }
}

extension AsyncAwaitCodeGenParameters {
    var asyncOperationStubs: CodeGenFeatureStatus {
        return .disabled
    }
}

struct SmokeFrameworkCodeGen: Codable {
    let modelFilePath: String
    let baseName: String
    let applicationSuffix: String?
    let generationType: GenerationType
    let applicationDescription: String?
    let modelOverride: ModelOverride?
    let httpClientConfiguration: HttpClientConfiguration?
    let asyncAwait: AsyncAwaitCodeGenParameters?
    let initializationType: InitializationType?
    let testDiscovery: CodeGenFeatureStatus?
    let mainAnnotation: CodeGenFeatureStatus?
    let operationStubGenerationRule: OperationStubGenerationRule
}
