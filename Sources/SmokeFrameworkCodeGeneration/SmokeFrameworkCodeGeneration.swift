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
//  ServiceModelCodeGenerator
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import SmokeAWSModelGenerate

/**
 The supported generation types.
 */
public enum GenerationType: String, Codable {
    case server
    case serverWithPlugin
    case serverUpdate
    case serverUpdateWithPlugin
    case codeGenModel
    case codeGenClient
    case codeGenHttp1
    
    var needsModel: Bool {
        return self == .server || self == .serverUpdate || self == .codeGenModel
    }
    
    var needsClient: Bool {
        return self == .server || self == .serverUpdate || self == .codeGenClient
    }
    
    var needsHttp1: Bool {
        return self == .server || self == .serverUpdate || self == .codeGenHttp1
    }
    
    var isNotCodeGenPlugIn: Bool {
        return self != .codeGenModel && self != .codeGenClient && self != .codeGenHttp1
    }
    
    var isUpdate: Bool {
        return self == .serverUpdate || self == .serverUpdateWithPlugin
    }
    
    var isWithPlugin: Bool {
        return self == .serverWithPlugin || self == .serverUpdateWithPlugin
    }
}

public struct ServiceIntegration: Codable {
    let contextTypeName: String?
}

public struct ServiceIntegrations: Codable {
    let http: ServiceIntegration?
}

public enum InitializationType: String, Codable {
    case original = "ORIGINAL"
    case streamlined = "STREAMLINED"
}

public enum OperationStubGeneration {
    case functionWithinContext
    case standaloneFunction
}

public enum OperationStubGenerationRule: Codable {
    case allFunctionsWithinContext
    case allStandaloneFunctions
    case allFunctionsWithinContextExceptStandaloneFunctionsFor([String])
    case allStandaloneFunctionsExceptFunctionsWithinContextFor([String])
    
    enum CodingKeys: String, CodingKey {
        case mode
        case operationsWithStandaloneFunctions
        case operationsWithFunctionsWithinContext
    }
    
    enum Mode: String, Codable {
        case allFunctionsWithinContext
        case allStandaloneFunctions
        case allFunctionsWithinContextExceptForSpecifiedStandaloneFunctions
        case allStandaloneFunctionsExceptForSpecifiedFunctionsWithinContext
    }
    
    var mode: Mode {
        switch self {
        case .allFunctionsWithinContext:
            return .allFunctionsWithinContext
        case .allStandaloneFunctions:
            return .allStandaloneFunctions
        case .allFunctionsWithinContextExceptStandaloneFunctionsFor:
            return .allFunctionsWithinContextExceptForSpecifiedStandaloneFunctions
        case .allStandaloneFunctionsExceptFunctionsWithinContextFor:
            return .allStandaloneFunctionsExceptForSpecifiedFunctionsWithinContext
        }
    }
    
    public func getStubGeneration(forOperation operation: String) -> OperationStubGeneration {
        switch self {
        case .allFunctionsWithinContext:
            return .functionWithinContext
        case .allStandaloneFunctions:
            return .standaloneFunction
        case .allFunctionsWithinContextExceptStandaloneFunctionsFor(let whitelist):
            return whitelist.contains(operation) ? .standaloneFunction : .functionWithinContext
        case .allStandaloneFunctionsExceptFunctionsWithinContextFor(let whitelist):
            return whitelist.contains(operation) ? .functionWithinContext : .standaloneFunction
        }
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let mode = try values.decode(Mode.self, forKey: .mode)
        
        switch mode {
        case .allFunctionsWithinContext:
            self = .allFunctionsWithinContext
        case .allStandaloneFunctions:
            self = .allStandaloneFunctions
        case .allFunctionsWithinContextExceptForSpecifiedStandaloneFunctions:
            let exceptions = try values.decode([String].self, forKey: .operationsWithStandaloneFunctions)
            self = .allFunctionsWithinContextExceptStandaloneFunctionsFor(exceptions)
        case .allStandaloneFunctionsExceptForSpecifiedFunctionsWithinContext:
            let exceptions = try values.decode([String].self, forKey: .operationsWithFunctionsWithinContext)
            self = .allStandaloneFunctionsExceptFunctionsWithinContextFor(exceptions)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.mode, forKey: .mode)
        
        switch self {
        case .allFunctionsWithinContextExceptStandaloneFunctionsFor(let whitelist):
            try container.encode(whitelist, forKey: .operationsWithStandaloneFunctions)
        case .allStandaloneFunctionsExceptFunctionsWithinContextFor(let whitelist):
            try container.encode(whitelist, forKey: .operationsWithFunctionsWithinContext)
        case .allFunctionsWithinContext, .allStandaloneFunctions:
            break
        }
    }
}

public struct SmokeFrameworkCodeGeneration {
    
    public static func generateFromModel<ModelType: ServiceModel>(
        modelFilePath: String,
        modelType: ModelType.Type,
        generationType: GenerationType,
        modelTargetName: String, clientTargetName: String,
        http1IntegrationTargetName: String,
        integrations: ServiceIntegrations?,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        operationStubGenerationRule: OperationStubGenerationRule,
        asyncOperationStubs: CodeGenFeatureStatus,
        eventLoopFutureOperationHandlers: CodeGenFeatureStatus,
        initializationType: InitializationType,
        testDiscovery: CodeGenFeatureStatus,
        mainAnnotation: CodeGenFeatureStatus,
        asyncInitialization: CodeGenFeatureStatus,
        modelOverride: ModelOverride<ModelType.OverridesType>?) throws
    -> ModelType {
        let targetSupport = SmokeFrameworkTargetSupport(modelTargetName: modelTargetName, clientTargetName: clientTargetName,
                                                        http1IntegrationTargetName: http1IntegrationTargetName)
    
        return try ServiceModelGenerate.generateFromModel(
            modelFilePath: modelFilePath,
            customizations: customizations,
            applicationDescription: applicationDescription,
            modelOverride: modelOverride,
            targetSupport: targetSupport) { (codeGenerator, serviceModel) in
                try codeGenerator.generateFromModel(serviceModel: serviceModel, generationType: generationType,
                                                    integrations: integrations,
                                                    asyncAwaitClientAPIs: customizations.asyncAwaitAPIs,
                                                    eventLoopFutureClientAPIs: customizations.eventLoopFutureClientAPIs,
                                                    minimumCompilerSupport: customizations.minimumCompilerSupport,
                                                    clientConfigurationType: customizations.clientConfigurationType,
                                                    initializationType: initializationType,
                                                    testDiscovery: testDiscovery,
                                                    mainAnnotation: mainAnnotation,
                                                    asyncInitialization: asyncInitialization,
                                                    operationStubGenerationRule: operationStubGenerationRule,
                                                    asyncOperationStubs: asyncOperationStubs,
                                                    eventLoopFutureOperationHandlers: eventLoopFutureOperationHandlers)
            }
    }
}

public protocol HTTP1IntegrationTargetSupport {
    var http1IntegrationTargetName: String { get }
}

public struct SmokeFrameworkTargetSupport: ModelTargetSupport, ClientTargetSupport, HTTP1IntegrationTargetSupport {
    public let modelTargetName: String
    public let clientTargetName: String
    public let http1IntegrationTargetName: String
    
    public init(modelTargetName: String, clientTargetName: String,
                http1IntegrationTargetName: String) {
        self.modelTargetName = modelTargetName
        self.clientTargetName = clientTargetName
        self.http1IntegrationTargetName = http1IntegrationTargetName
    }
}

extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & ClientTargetSupport & HTTP1IntegrationTargetSupport {
    
    func generateFromModel(serviceModel: ModelType,
                           generationType: GenerationType,
                           integrations: ServiceIntegrations?,
                           asyncAwaitClientAPIs: CodeGenFeatureStatus,
                           eventLoopFutureClientAPIs: CodeGenFeatureStatus,
                           minimumCompilerSupport: MinimumCompilerSupport,
                           clientConfigurationType: ClientConfigurationType,
                           initializationType: InitializationType,
                           testDiscovery: CodeGenFeatureStatus,
                           mainAnnotation: CodeGenFeatureStatus,
                           asyncInitialization: CodeGenFeatureStatus,
                           operationStubGenerationRule: OperationStubGenerationRule,
                           asyncOperationStubs: CodeGenFeatureStatus,
                           eventLoopFutureOperationHandlers: CodeGenFeatureStatus) throws {
        let clientProtocolDelegate = ClientProtocolDelegate<ModelType, TargetSupportType>(
            baseName: applicationDescription.baseName,
            asyncAwaitAPIs: asyncAwaitClientAPIs,
            eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
            minimumCompilerSupport: minimumCompilerSupport)
        let mockClientDelegate = MockClientDelegate<ModelType, TargetSupportType>(
            baseName: applicationDescription.baseName,
            isThrowingMock: false,
            asyncAwaitAPIs: asyncAwaitClientAPIs,
            eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
            minimumCompilerSupport: minimumCompilerSupport)
        let throwingClientDelegate = MockClientDelegate<ModelType, TargetSupportType>(
            baseName: applicationDescription.baseName,
            isThrowingMock: true,
            asyncAwaitAPIs: asyncAwaitClientAPIs,
            eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
            minimumCompilerSupport: minimumCompilerSupport)
        let awsClientDelegate = APIGatewayClientDelegate<ModelType, TargetSupportType>(
            baseName: applicationDescription.baseName, asyncAwaitAPIs: asyncAwaitClientAPIs,
            addSendableConformance: customizations.addSendableConformance,
            eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
            minimumCompilerSupport: minimumCompilerSupport,
            contentType: "application/json", signAllHeaders: false,
            defaultInvocationTraceContext: InvocationTraceContextDeclaration(name: "SmokeInvocationTraceContext", importPackage: "SmokeOperationsHTTP1"))
        let awsModelErrorsDelegate = SmokeFrameworkModelErrorsDelegate()
        let defaultContextTypeName = "\(applicationDescription.baseName)OperationsContext"
        
        if generationType.isNotCodeGenPlugIn {
            let contextTypeName = integrations?.http?.contextTypeName ?? defaultContextTypeName
            
            generateServerOperationHandlerStubs(generationType: generationType, operationStubGenerationRule: operationStubGenerationRule,
                                                asyncOperationStubs: asyncOperationStubs)
            generateServerApplicationFiles(generationType: generationType, mainAnnotation: mainAnnotation)
            generateOperationsContext(generationType: generationType)
            generateOperationsContextGenerator(generationType: generationType, contextTypeName: contextTypeName,
                                               initializationType: initializationType,
                                               mainAnnotation: mainAnnotation, asyncInitialization: asyncInitialization)
            generateOperationTests(generationType: generationType, operationStubGenerationRule: operationStubGenerationRule,
                                   asyncOperationStubs: asyncOperationStubs, testDiscovery: testDiscovery)
            generateTestConfiguration(generationType: generationType)
            if case .disabled = testDiscovery {
                generateLinuxMain()
            }
        }
        
        if generationType.needsClient {
            let generatorFileType: ClientFileType
            switch clientConfigurationType {
            case .configurationObject:
                generatorFileType = .clientConfiguration
            case .generator:
                generatorFileType = .clientGenerator
            }
            
            generateSmokeFrameworkClient(delegate: clientProtocolDelegate, fileType: .clientImplementation)
            generateSmokeFrameworkClient(delegate: mockClientDelegate, fileType: .clientImplementation)
            generateSmokeFrameworkClient(delegate: throwingClientDelegate, fileType: .clientImplementation)
            generateSmokeFrameworkClient(delegate: awsClientDelegate, fileType: .clientImplementation)
            generateSmokeFrameworkClient(delegate: awsClientDelegate, fileType: generatorFileType)
            generateAWSOperationsReporting()
            generateAWSInvocationsReporting()
            generateModelOperationClientInput()
            generateModelOperationClientOutput()
        } else if generationType.isWithPlugin {
            generateCodeGenDummyFile(targetName: self.targetSupport.clientTargetName,
                                     plugin: "SmokeFrameworkGenerateClient",
                                     generationType: generationType)
        }
        
        if generationType.needsModel {
            generateModelOperationsEnum()
            generateModelStructures()
            generateModelTypes()
            generateModelErrors(delegate: awsModelErrorsDelegate)
            generateDefaultInstances(generationType: .internalTypes)
        } else if generationType.isWithPlugin {
            generateCodeGenDummyFile(targetName: self.targetSupport.modelTargetName,
                                     plugin: "SmokeFrameworkGenerateModel",
                                     generationType: generationType)
        }
        
        if generationType.needsHttp1 {
            let contextTypeName = integrations?.http?.contextTypeName ?? defaultContextTypeName
            
            generateModelOperationHTTPInput()
            generateModelOperationHTTPOutput()
            generateServerHanderSelector(operationStubGenerationRule: operationStubGenerationRule,
                                         initializationType: initializationType,
                                         contextTypeName: contextTypeName,
                                         eventLoopFutureOperationHandlers: eventLoopFutureOperationHandlers)
            
            if initializationType == .streamlined {
                generateStreamlinedOperationsContextProtocolGenerator(generationType: generationType,
                                                                      contextTypeName: contextTypeName,
                                                                      asyncInitialization: asyncInitialization)
            }
        } else if generationType.isWithPlugin {
            generateCodeGenDummyFile(targetName: self.targetSupport.http1IntegrationTargetName,
                                     plugin: "SmokeFrameworkGenerateHttp1",
                                     generationType: generationType)
        }
    }
    
    private func generateSmokeFrameworkClient<DelegateType: ModelClientDelegate>(delegate: DelegateType, fileType: ClientFileType)
    where DelegateType.TargetSupportType == TargetSupportType, DelegateType.ModelType == ModelType {
        let defaultTraceContextType = DefaultTraceContextType(typeName: "SmokeInvocationTraceContext",
                                                              importTargetName: "SmokeOperationsHTTP1")
        generateClient(delegate: delegate, fileType: fileType, defaultTraceContextType: defaultTraceContextType)
    }

    // Due to a current limitation of the SPM plugins for code generators, a placeholder Swift file
    // is required in each package to avoid the package as being seen as empty. These files need to
    // be a Swift file but doesn't require any particular contents.
    private func generateCodeGenDummyFile(targetName: String,
                                          plugin: String,
                                          generationType: GenerationType) {
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
        let fileName = "codegen.swift"
        let filePath = "\(baseFilePath)/Sources/\(targetName)"

        if generationType.isUpdate {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            //  This package is code generated by the smoke-framework-application-generate \(plugin) plugin.
            //
            """)
        
        fileBuilder.write(toFile: fileName,
                          atFilePath: filePath)
    }
}
