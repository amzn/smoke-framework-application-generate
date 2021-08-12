//
//  SmokeFrameworkCodeGen.swift
//  SmokeFrameworkApplicationGenerate
//

import SmokeFrameworkCodeGeneration
import ServiceModelEntities
import ServiceModelCodeGeneration

struct SmokeFrameworkCodeGen: Codable {
    let modelFilePath: String
    let baseName: String
    let applicationSuffix: String?
    let generationType: GenerationType
    let applicationDescription: String?
    let modelOverride: ModelOverride?
    let httpClientConfiguration: HttpClientConfiguration?
    let initializationType: InitializationType?
    let operationStubGenerationRule: OperationStubGenerationRule
}
