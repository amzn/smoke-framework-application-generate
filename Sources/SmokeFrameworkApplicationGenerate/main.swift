// Copyright 2019-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  main.swift
//  SmokeFrameworkApplicationGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import SmokeFrameworkCodeGeneration
import SwaggerServiceModel
import ArgumentParser
import OpenAPIServiceModel

private let configFileName = "smoke-framework-codegen.json"

enum ConfigurationProvider<Type> {
    case provided(Type)
    case atPath(String)
}

struct Parameters {
    var modelFilePath: String
    var baseName: String
    var applicationSuffix: String?
    var baseFilePath: String
    var generationType: GenerationType
    var applicationDescription: String?
    var modelOverride: ConfigurationProvider<ModelOverride>?
    var generateCodeGenConfig: Bool?
    var httpClientConfiguration: ConfigurationProvider<HttpClientConfiguration>?
    var initializationType: InitializationType?
    var operationStubGenerationRule: OperationStubGenerationRule
    var swaggerFileVersion: Int
}

private func getModelOverride(modelOverridePath: String?) throws -> ModelOverride? {
    let modelOverride: ModelOverride?
    if let modelOverridePath = modelOverridePath {
        let overrideFile = FileHandle(forReadingAtPath: modelOverridePath)
        
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(modelOverridePath)' doesn't exist.")
        }
        
        modelOverride = try JSONDecoder().decode(ModelOverride.self, from: overrideData)
    } else {
        modelOverride = nil
    }
    
    return modelOverride
}

private func getHttpClientConfiguration(httpClientConfigurationPath: String?) throws
-> HttpClientConfiguration? {
    let httpClientConfiguration: HttpClientConfiguration?
    if let httpClientConfigurationPath = httpClientConfigurationPath {
        let overrideFile = FileHandle(forReadingAtPath: httpClientConfigurationPath)
        
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(httpClientConfigurationPath) doesn't exist.'")
        }
        
        httpClientConfiguration = try JSONDecoder().decode(HttpClientConfiguration.self,
                                                           from: overrideData)
    } else {
        httpClientConfiguration = nil
    }
    
    return httpClientConfiguration
}

private func startCodeGeneration(
        httpClientConfiguration: HttpClientConfiguration,
        baseName: String, baseFilePath: String,
        applicationDescription: String, applicationSuffix: String,
        modelFilePath: String, generationType: GenerationType,
        initializationType: InitializationType,
        operationStubGenerationRule: OperationStubGenerationRule,
        modelOverride: ModelOverride?,
    swaggerFileVersion: Int) throws -> ServiceModel {
    let validationErrorDeclaration = ErrorDeclaration.external(
        libraryImport: "SmokeOperations",
        errorType: "SmokeOperationsError")
    let unrecognizedErrorDeclaration = ErrorDeclaration.internal
    let customizations = CodeGenerationCustomizations(
        validationErrorDeclaration: validationErrorDeclaration,
        unrecognizedErrorDeclaration: unrecognizedErrorDeclaration,
        asyncAwaitGeneration: .none,
        generateModelShapeConversions: true,
        optionalsInitializeEmpty: true,
        fileHeader: nil,
        httpClientConfiguration: httpClientConfiguration)
    
    let fullApplicationDescription = ApplicationDescription(
        baseName: baseName,
        baseFilePath: baseFilePath,
        applicationDescription: applicationDescription,
        applicationSuffix: applicationSuffix)
    
    if swaggerFileVersion == 3 {
        return try SmokeFrameworkCodeGeneration.generateFromModel(
            modelFilePath: modelFilePath,
            modelType: OpenAPIServiceModel.self,
            generationType: generationType,
            customizations: customizations,
            applicationDescription: fullApplicationDescription,
            operationStubGenerationRule: operationStubGenerationRule,
            initializationType: initializationType,
            modelOverride: modelOverride)
    } else if swaggerFileVersion == 2 {
        return try SmokeFrameworkCodeGeneration.generateFromModel(
            modelFilePath: modelFilePath,
            modelType: SwaggerServiceModel.self,
            generationType: generationType,
            customizations: customizations,
            applicationDescription: fullApplicationDescription,
            operationStubGenerationRule: operationStubGenerationRule,
            initializationType: initializationType,
            modelOverride: modelOverride)
    } else {
        fatalError("Invalid swagger version.")
    }
}

func handleApplication(parameters: Parameters) throws {
    let modelOverride: ModelOverride?
    switch parameters.modelOverride {
    case .provided(let provided):
        modelOverride = provided
    case .atPath(let modelOverridePath):
        modelOverride = try getModelOverride(modelOverridePath: modelOverridePath)
    case .none:
        modelOverride = nil
    }
    
    let httpClientConfigurationOptional: HttpClientConfiguration?
    switch parameters.httpClientConfiguration {
    case .provided(let provided):
        httpClientConfigurationOptional = provided
    case .atPath(let httpClientConfigurationPath):
        httpClientConfigurationOptional = try getHttpClientConfiguration(
            httpClientConfigurationPath: httpClientConfigurationPath)
    case .none:
        httpClientConfigurationOptional = nil
    }
    
    let httpClientConfiguration = httpClientConfigurationOptional ?? HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [])
    
    let applicationSuffix = parameters.applicationSuffix ?? "Service"

    // Construct an application description if there isn't one
    let applicationDescription: String
    if let theApplicationDescription = parameters.applicationDescription {
        applicationDescription = theApplicationDescription
    } else {
        applicationDescription = "The \(parameters.baseName)\(applicationSuffix)."
    }
    
    let model = try startCodeGeneration(
        httpClientConfiguration: httpClientConfiguration,
        baseName: parameters.baseName, baseFilePath: parameters.baseFilePath,
        applicationDescription: applicationDescription,
        applicationSuffix: applicationSuffix, modelFilePath: parameters.modelFilePath,
        generationType: parameters.generationType,
        initializationType: parameters.initializationType ?? .original,
        operationStubGenerationRule: parameters.operationStubGenerationRule,
        modelOverride: modelOverride, swaggerFileVersion: parameters.swaggerFileVersion)
    
    if (parameters.generateCodeGenConfig ?? false) {
        let parameterModelFilePath = parameters.modelFilePath
        let parameterModelFilePathWithSeperator = parameters.baseFilePath + "/"
        
        let modelFilePath: String
        if parameterModelFilePath.starts(with: parameterModelFilePathWithSeperator) {
            modelFilePath = String(parameterModelFilePath.dropFirst(parameterModelFilePathWithSeperator.count))
        } else if parameterModelFilePath.starts(with: parameterModelFilePath) {
            modelFilePath = String(parameterModelFilePath.dropFirst(parameterModelFilePath.count))
        } else {
            modelFilePath = parameterModelFilePath
        }
        
        let existingOperations = Array(model.operationDescriptions.keys)
        
        let smokeFrameworkCodeGen = SmokeFrameworkCodeGen(modelFilePath: modelFilePath,
                                                          baseName: parameters.baseName,
                                                          applicationSuffix: parameters.applicationSuffix,
                                                          generationType: .serverUpdate,
                                                          applicationDescription: parameters.applicationDescription,
                                                          modelOverride: modelOverride,
                                                          httpClientConfiguration: httpClientConfigurationOptional,
                                                          initializationType: parameters.initializationType,
                                                          operationStubGenerationRule: .allFunctionsWithinContextExceptStandaloneFunctionsFor(existingOperations.sorted(by: <)))
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        let data = try jsonEncoder.encode(smokeFrameworkCodeGen)
        
        try data.write(to: URL.init(fileURLWithPath: "\(parameters.baseFilePath)/\(configFileName)"))
    }
}

SmokeFrameworkApplicationGenerateCommand.main()
