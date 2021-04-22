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
import ArgumentParser

/**
 The supported generation types.
 */
public enum GenerationType: String, Codable, ExpressibleByArgument {
    case server
    case serverUpdate
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
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        operationStubGenerationRule: OperationStubGenerationRule,
        modelOverride: ModelOverride?) throws -> ModelType {
            func generatorFunction(codeGenerator: ServiceModelCodeGenerator,
                                   serviceModel: ModelType) throws {
                try codeGenerator.generateFromModel(serviceModel: serviceModel, generationType: generationType,
                                                    operationStubGenerationRule: operationStubGenerationRule)
            }
        
            return try ServiceModelGenerate.generateFromModel(
                    modelFilePath: modelFilePath,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    generatorFunction: generatorFunction)
    }
}

extension ServiceModelCodeGenerator {
    
    func generateFromModel<ModelType: ServiceModel>(serviceModel: ModelType,
                                                    generationType: GenerationType,
                                                    operationStubGenerationRule: OperationStubGenerationRule) throws {
        let clientProtocolDelegate = ClientProtocolDelegate(
            baseName: applicationDescription.baseName)
        let mockClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: false)
        let throwingClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: true)
        let awsClientDelegate = APIGatewayClientDelegate(
            baseName: applicationDescription.baseName, asyncResultType: nil,
            contentType: "application/json", signAllHeaders: false,
            defaultInvocationTraceContext: InvocationTraceContextDeclaration(name: "SmokeInvocationTraceContext", importPackage: "SmokeOperationsHTTP1"))
        let awsModelErrorsDelegate = SmokeFrameworkModelErrorsDelegate()
        
        generateServerOperationHandlerStubs(generationType: generationType, operationStubGenerationRule: operationStubGenerationRule)
        generateServerHanderSelector(operationStubGenerationRule: operationStubGenerationRule)
        generateServerApplicationFiles(generationType: generationType)
        generateOperationsContext(generationType: generationType)
        generateOperationsContextGenerator(generationType: generationType)
        generateOperationTests(generationType: generationType, operationStubGenerationRule: operationStubGenerationRule)
        generateTestConfiguration(generationType: generationType)
        generateLinuxMain()
        
        generateClient(delegate: clientProtocolDelegate, isGenerator: false)
        generateClient(delegate: mockClientDelegate, isGenerator: false)
        generateClient(delegate: throwingClientDelegate, isGenerator: false)
        generateClient(delegate: awsClientDelegate, isGenerator: false)
        generateClient(delegate: awsClientDelegate, isGenerator: true)
        generateModelOperationsEnum()
        generateOperationsReporting()
        generateInvocationsReporting()
        generateModelOperationClientInput()
        generateModelOperationClientOutput()
        generateModelOperationHTTPInput()
        generateModelOperationHTTPOutput()
        generateModelStructures()
        generateModelTypes()
        generateModelErrors(delegate: awsModelErrorsDelegate)
        generateDefaultInstances(generationType: .internalTypes)
    }
}
