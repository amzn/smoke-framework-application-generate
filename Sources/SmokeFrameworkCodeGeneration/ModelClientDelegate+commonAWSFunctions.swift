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
//  ModelClientDelegate+commonAWSFunctions.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import SmokeAWSModelGenerate

private struct HttpClientSignatureParameters {
    let targetOrVersionParameter: String
    let targetAssignment: String
    let contentTypeAssignment: String
}

extension ModelClientDelegate {
    func addAWSClientFileHeader(fileBuilder: FileBuilder, baseName: String) {
        fileBuilder.appendLine("""
            import SmokeAWSCore
            import SmokeAWSHttp
            import NIO
            import NIOHTTP1
            
            public enum \(baseName)ClientError: Swift.Error {
                case invalidEndpoint(String)
                case unsupportedPayload
                case unknownError(String?)
            }
            """)
    }
    
    private func createDelegate(name: String, fileBuilder: FileBuilder, delegateName: String, errorType: String, parameters: [String]?) {
        guard let concreteParameters = parameters, !concreteParameters.isEmpty else {
            fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>()")
            return
        }
        
        fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>(")
        
        fileBuilder.incIndent()
        concreteParameters.enumerated().forEach { (index, parameter) in
            if index == concreteParameters.count - 1 {
                fileBuilder.appendLine("\(parameter))")
            } else {
                fileBuilder.appendLine("\(parameter), ")
            }
        }
        fileBuilder.decIndent()
    }
    
    private func addDelegateForHttpClient(httpClientConfiguration: HttpClientConfiguration, isQuery: Bool, baseName: String,
                                          fileBuilder: FileBuilder) {
        if isQuery {
            // pass a QueryXMLAWSHttpClientDelegate to the AWS client
            createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: "XMLAWSHttpClientDelegate", errorType: "\(baseName)Error",
                parameters: httpClientConfiguration.clientDelegateParameters)
            fileBuilder.appendEmptyLine()
            
            httpClientConfiguration.additionalClients?.forEach { (key, value) in
                let postfix = key.startingWithUppercase
                createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: "XMLAWSHttpClientDelegate",
                               errorType: "\(baseName)Error", parameters: value.clientDelegateParameters)
                fileBuilder.appendEmptyLine()
            }
        } else {
            // pass a JSONAWSHttpClientDelegate to the AWS client
            createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: "JSONAWSHttpClientDelegate", errorType: "\(baseName)Error",
                parameters: httpClientConfiguration.clientDelegateParameters)
            fileBuilder.appendEmptyLine()
            
            httpClientConfiguration.additionalClients?.forEach { (key, value) in
                let postfix = key.startingWithUppercase
                createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: "JSONAWSHttpClientDelegate",
                               errorType: "\(baseName)Error", parameters: value.clientDelegateParameters)
                fileBuilder.appendEmptyLine()
            }
        }
    }
    
    private func addInstanceVariables(isQuery: Bool, httpClientConfiguration: HttpClientConfiguration,
                                      codeGenerator: ServiceModelCodeGenerator, clientAttributes: AWSClientAttributes,
                                      targetsAPIGateway: Bool, targetValue: String, fileBuilder: FileBuilder) -> HttpClientSignatureParameters {
        let targetOrVersionParameter: String
        let targetAssignment: String
        let contentTypeAssignment: String
        // Use a specific initializer for queries
        if isQuery {
            fileBuilder.appendLine("""
                let httpClient: HTTPClient
                """)
            
            httpClientConfiguration.additionalClients?.forEach { (key, _) in
                let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
                fileBuilder.appendLine("""
                    let \(variableName): HTTPClient
                    """)
            }
            
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let apiVersion: String
                let target: String?
                let credentialsProvider: CredentialsProvider
                """)
            
            // accept the api version rather than the target
            targetOrVersionParameter = "apiVersion: String = \"\(clientAttributes.apiVersion)\""
            targetAssignment = "self.target = nil"
            
            // use 'application/octet-stream' as the content type
            contentTypeAssignment = "contentType: String = \"application/octet-stream\""
        } else {
            fileBuilder.appendLine("""
                let httpClient: HTTPClient
                """)
            
            httpClientConfiguration.additionalClients?.forEach { (key, _) in
                let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
                fileBuilder.appendLine("""
                    let \(variableName): HTTPClient
                    """)
            }
            
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let target: String?
                let credentialsProvider: CredentialsProvider
                """)
            
            // If this is an API Gateway client, store the stage
            if targetsAPIGateway {
                fileBuilder.appendLine("""
                    let stage: String
                    """)
            }
            
            // accept the target and pass it to the AWS client
            targetOrVersionParameter = "target: String? = \(targetValue)"
            targetAssignment = "self.target = target"
            
            // use the content type from the client attributes as the default
            contentTypeAssignment = "contentType: String = \"\(clientAttributes.contentType)\""
        }
        
        return HttpClientSignatureParameters(targetOrVersionParameter: targetOrVersionParameter,
                                             targetAssignment: targetAssignment,
                                             contentTypeAssignment: contentTypeAssignment)
    }
    
    fileprivate func addInitializerBody(httpClientConfiguration: HttpClientConfiguration, isQuery: Bool, baseName: String,
                                        codeGenerator: ServiceModelCodeGenerator, regionAssignmentPostfix: String,
                                        signatureParameters: HttpClientSignatureParameters, targetsAPIGateway: Bool, fileBuilder: FileBuilder) {
        addDelegateForHttpClient(httpClientConfiguration: httpClientConfiguration, isQuery: isQuery,
                                 baseName: baseName, fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            self.httpClient = HTTPClient(endpointHostName: endpointHostName,
                                         endpointPort: endpointPort,
                                         contentType: contentType,
                                         clientDelegate: clientDelegate,
                                         connectionTimeoutSeconds: connectionTimeoutSeconds)
            """)
        
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            let postfix = key.startingWithUppercase
            fileBuilder.appendLine("""
                self.\(variableName) = HTTPClient(endpointHostName: endpointHostName,
                endpointPort: endpointPort,
                contentType: contentType,
                clientDelegate: clientDelegateFor\(postfix),
                connectionTimeoutSeconds: connectionTimeoutSeconds)
                """)
        }
        
        fileBuilder.appendLine("""
            self.awsRegion = awsRegion\(regionAssignmentPostfix)
            self.service = service
            \(signatureParameters.targetAssignment)
            self.credentialsProvider = credentialsProvider
            """)
        
        // If this is a query, set the apiVersion
        if isQuery {
            fileBuilder.appendLine("""
                self.apiVersion = apiVersion
                """)
        }
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                self.stage = stage
                """)
        }
    }
    
    func addAWSClientCommonFunctions(fileBuilder: FileBuilder, baseName: String,
                                     clientAttributes: AWSClientAttributes,
                                     codeGenerator: ServiceModelCodeGenerator,
                                     targetsAPIGateway: Bool,
                                     isQuery: Bool) {
        let targetValue: String
        if let target = clientAttributes.target {
            targetValue = "\"\(target)\""
        } else {
            targetValue = "nil"
        }
        
        let endpointDefault: String
        let regionDefault: String
        let regionAssignmentPostfix: String
        // If there is a global endpoint, use it as the default endpoint
        // and make the region optional and nil by default
        if let globalEndpoint = clientAttributes.globalEndpoint {
            endpointDefault = " = \"\(globalEndpoint)\""
            regionDefault = "? = nil"
            regionAssignmentPostfix = " ?? .us_east_1"
        } else {
            endpointDefault = ""
            regionDefault = ""
            regionAssignmentPostfix = ""
        }
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let signatureParameters = addInstanceVariables(isQuery: isQuery, httpClientConfiguration: httpClientConfiguration,
                                                       codeGenerator: codeGenerator, clientAttributes: clientAttributes,
                                                       targetsAPIGateway: targetsAPIGateway, targetValue: targetValue, fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            
            public init(credentialsProvider: CredentialsProvider, awsRegion: AWSRegion\(regionDefault),
                        endpointHostName: String\(endpointDefault),
            """)
        
        // If this is an API Gateway client, accept the stage in the constructor
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                            stage: String,
                """)
        }
        
        fileBuilder.appendLine("""
                        endpointPort: Int = 443,
                        service: String = "\(clientAttributes.service)",
                        \(signatureParameters.contentTypeAssignment),
                        \(signatureParameters.targetOrVersionParameter),
                        connectionTimeoutSeconds: Int = 10) {
            """)
        
        fileBuilder.incIndent()
        addInitializerBody(httpClientConfiguration: httpClientConfiguration, isQuery: isQuery, baseName: baseName,
                           codeGenerator: codeGenerator, regionAssignmentPostfix: regionAssignmentPostfix,
                           signatureParameters: signatureParameters, targetsAPIGateway: targetsAPIGateway, fileBuilder: fileBuilder)
        fileBuilder.decIndent()
        fileBuilder.appendLine("}")
    }
}
