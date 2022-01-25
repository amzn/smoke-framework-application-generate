//
//  SmokeFrameworkCodeGen.swift
//  SmokeFrameworkApplicationGenerate
//

import SmokeFrameworkCodeGeneration
import ServiceModelEntities
import ServiceModelCodeGeneration

struct AsyncAwaitCodeGenParameters: Codable {
    let clientAPIs: CodeGenFeatureStatus
    let asyncOperationStubs: CodeGenFeatureStatus
    let asyncInitialization: CodeGenFeatureStatus

    static var `default`: AsyncAwaitCodeGenParameters {
        return AsyncAwaitCodeGenParameters(clientAPIs: .enabled,
                                           asyncOperationStubs: .enabled,
                                           asyncInitialization: .disabled)
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
    let eventLoopFutureOperationHandlers: CodeGenFeatureStatus?
    let initializationType: InitializationType?
    let testDiscovery: CodeGenFeatureStatus?
    let mainAnnotation: CodeGenFeatureStatus?
    let operationStubGenerationRule: OperationStubGenerationRule
}
