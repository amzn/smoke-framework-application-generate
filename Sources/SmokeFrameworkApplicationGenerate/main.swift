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
    var asyncAwait: AsyncAwaitCodeGenParameters?
    var eventLoopFutureOperationHandlers: CodeGenFeatureStatus?
    var initializationType: InitializationType?
    var testDiscovery: CodeGenFeatureStatus?
    var mainAnnotation: CodeGenFeatureStatus?
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
        asyncAwait: AsyncAwaitCodeGenParameters,
        eventLoopFutureOperationHandlers: CodeGenFeatureStatus,
        initializationType: InitializationType,
        testDiscovery: CodeGenFeatureStatus,
        mainAnnotation: CodeGenFeatureStatus,
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
        asyncAwaitAPIs: asyncAwait.clientAPIs,
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
            asyncOperationStubs: asyncAwait.asyncOperationStubs,
            eventLoopFutureOperationHandlers: eventLoopFutureOperationHandlers,
            initializationType: initializationType,
            testDiscovery: testDiscovery,
            mainAnnotation: mainAnnotation,
            asyncInitialization: asyncAwait.asyncInitialization,
            modelOverride: modelOverride)
    } else if swaggerFileVersion == 2 {
        return try SmokeFrameworkCodeGeneration.generateFromModel(
            modelFilePath: modelFilePath,
            modelType: SwaggerServiceModel.self,
            generationType: generationType,
            customizations: customizations,
            applicationDescription: fullApplicationDescription,
            operationStubGenerationRule: operationStubGenerationRule,
            asyncOperationStubs: asyncAwait.asyncOperationStubs,
            eventLoopFutureOperationHandlers: eventLoopFutureOperationHandlers,
            initializationType: initializationType,
            testDiscovery: testDiscovery,
            mainAnnotation: mainAnnotation,
            asyncInitialization: asyncAwait.asyncInitialization,
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
        asyncAwait: parameters.asyncAwait ?? .default,
        eventLoopFutureOperationHandlers: parameters.eventLoopFutureOperationHandlers ?? .disabled,
        initializationType: parameters.initializationType ?? .original,
        testDiscovery: parameters.testDiscovery ?? .disabled,
        mainAnnotation: parameters.mainAnnotation ?? .disabled,
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
                                                          asyncAwait: parameters.asyncAwait,
                                                          eventLoopFutureOperationHandlers: parameters.eventLoopFutureOperationHandlers,
                                                          initializationType: parameters.initializationType,
                                                          testDiscovery: parameters.testDiscovery,
                                                          mainAnnotation: parameters.mainAnnotation,
                                                          operationStubGenerationRule: .allFunctionsWithinContextExceptStandaloneFunctionsFor(existingOperations.sorted(by: <)))
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        let data = try jsonEncoder.encode(smokeFrameworkCodeGen)
        
        try data.write(to: URL.init(fileURLWithPath: "\(parameters.baseFilePath)/\(configFileName)"))
    }
}

enum SmokeFrameworkApplicationGenerateCommandError: Error {
    case missingParameter(reason: String)
}

struct SmokeFrameworkApplicationGenerateCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "SmokeFrameworkApplicationGenerate",
            abstract: "Code generator for smoke-framework based applications."
        )
    }
    
    @Option(name: .customLong("model-path"), help: "The file path for the model definition.")
    var modelFilePath: String?
    
    @Option(name: .customLong("base-name"), help: """
        The base name for the generated libraries and executable.
        The generate executable will have the name-
          <base-name><application-suffix>.
        Libraries for the application will have names-
          <base-name><generator-defined-library-type-name>
        """)
    var baseName: String?
    
    @Option(name: .customLong("application-suffix"), help: "The suffix for the generated executable. [Service]")
    var applicationSuffix: String?
    
    @Option(name: .customLong("base-file-path"), help: "The file path to place the root of the generated Swift package.")
    var baseFilePath: String
    
    @Option(name: .customLong("generation-type"), help: "What code to generate. (server|serverUpdate)")
    var generationType: GenerationType?
    
    @Option(name: .customLong("application-description"), help: "A description of the application being created.")
    var applicationDescription: String?
    
    @Option(name: .customLong("model-override-path"), help: "The file path to model override parameters.")
    var modelOverridePath: String?
    
    @Option(name: .customLong("generate-code-gen-config"), help: "The file path to model override parameters.")
    var generateCodeGenConfig: Bool?
    
    @Option(name: .customLong("http-client-configuration-path"), help: """
         The file path to the configuration for the http client.
         If not specified, the http client will consider all
         known errors as unretryable and all unknown errors as
         unretryable.
        """)
    var httpClientConfigurationPath: String?
    
    @Option(name: .customLong("swagger-version"), help: "The swagger version to build the service model from.")
    var version: Int?

    mutating func run() throws {
        let configFile = FileHandle(forReadingAtPath: "\(baseFilePath)/\(configFileName)")
        
        let config: SmokeFrameworkCodeGen?
        if let configData = configFile?.readDataToEndOfFile() {
            config = try JSONDecoder().decode(SmokeFrameworkCodeGen.self, from: configData)
        } else {
            config = nil
        }
        
        let theModelFilePath: String
        if let modelFilePathOverride = modelFilePath {
            theModelFilePath = modelFilePathOverride
        } else if let modelFilePathFromConfig = config?.modelFilePath {
            // config specified an absolute path
            if modelFilePathFromConfig.starts(with: "/") {
                theModelFilePath = modelFilePathFromConfig
            } else {
                theModelFilePath = "\(baseFilePath)/\(modelFilePathFromConfig)"
            }
        } else {
            throw SmokeFrameworkApplicationGenerateCommandError.missingParameter(
                reason: "The model file path needs to be specified either in <base-path>/\(configFileName) or provided directly.")
        }
        
        let theBaseName: String
        if let baseNameOverride = baseName {
            theBaseName = baseNameOverride
        } else if let baseNameFromConfig = config?.baseName {
            theBaseName = baseNameFromConfig
        } else {
            throw SmokeFrameworkApplicationGenerateCommandError.missingParameter(
                reason: "The base name needs to be specified either in <base-path>/\(configFileName) or provided directly.")
        }
        
        let theApplicationSuffix: String?
        if let applicationSuffixOverride = applicationSuffix {
            theApplicationSuffix = applicationSuffixOverride
        } else if let applicationSuffixFromConfig = config?.applicationSuffix {
            theApplicationSuffix = applicationSuffixFromConfig
        } else {
            theApplicationSuffix = nil
        }
        
        let theGenerationType: GenerationType
        if let generationTypeOverride = generationType {
            theGenerationType = generationTypeOverride
        } else if let generationTypeFromConfig = config?.generationType {
            theGenerationType = generationTypeFromConfig
        } else {
            throw SmokeFrameworkApplicationGenerateCommandError.missingParameter(
                reason: "The generation type needs to be specified either in <base-path>/\(configFileName) or provided directly.")
        }
        
        let theApplicationDescription: String?
        if let applicationDescriptionOverride = applicationDescription {
            theApplicationDescription = applicationDescriptionOverride
        } else if let applicationDescriptionFromConfig = config?.applicationDescription {
            theApplicationDescription = applicationDescriptionFromConfig
        } else {
            theApplicationDescription = nil
        }
        
        let modelOverride: ConfigurationProvider<ModelOverride>?
        if let modelOverridePath = modelOverridePath {
            modelOverride = .atPath(modelOverridePath)
        } else if let modelOverrideFromConfig = config?.modelOverride {
            modelOverride = .provided(modelOverrideFromConfig)
        } else {
            modelOverride = nil
        }

        let httpClientConfiguration: ConfigurationProvider<HttpClientConfiguration>?
        if let httpClientConfigurationPath = httpClientConfigurationPath {
            httpClientConfiguration = .atPath(httpClientConfigurationPath)
        } else if let httpClientConfigurationFromConfig = config?.httpClientConfiguration {
            httpClientConfiguration = .provided(httpClientConfigurationFromConfig)
        } else {
            httpClientConfiguration = nil
        }
        
        let operationStubGenerationRule: OperationStubGenerationRule
        if let operationStubGenerationRuleFromConfig = config?.operationStubGenerationRule {
            operationStubGenerationRule = operationStubGenerationRuleFromConfig
        } else {
            operationStubGenerationRule = .allStandaloneFunctions
        }
        
        let theSwaggerVersion: Int
        if let versionOverride = version {
            theSwaggerVersion = versionOverride
        } else {
            theSwaggerVersion = 2
        }
        
        let parameters = Parameters(
            modelFilePath: theModelFilePath,
            baseName: theBaseName,
            applicationSuffix: theApplicationSuffix,
            baseFilePath: baseFilePath,
            generationType: theGenerationType,
            applicationDescription: theApplicationDescription,
            modelOverride: modelOverride,
            generateCodeGenConfig: generateCodeGenConfig ?? false,
            httpClientConfiguration: httpClientConfiguration,
            asyncAwait: config?.asyncAwait,
            eventLoopFutureOperationHandlers: config?.eventLoopFutureOperationHandlers,
            initializationType: config?.initializationType,
            testDiscovery: config?.testDiscovery,
            mainAnnotation: config?.mainAnnotation,
            operationStubGenerationRule: operationStubGenerationRule,
            swaggerFileVersion: theSwaggerVersion)
        
        try handleApplication(parameters: parameters)
    }
}

SmokeFrameworkApplicationGenerateCommand.main()
