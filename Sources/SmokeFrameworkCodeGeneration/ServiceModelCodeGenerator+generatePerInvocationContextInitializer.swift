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
//  ServiceModelCodeGenerator+generatePerInvocationContextInitializer.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator where TargetSupportType: HTTP1IntegrationTargetSupport {
    /**
     Generate the stub operations context generator for the generated application.
     */
    func generateOperationsContextGenerator(generationType: GenerationType,
                                            contextTypeName: String,
                                            initializationType: InitializationType,
                                            mainAnnotation: CodeGenFeatureStatus,
                                            asyncInitialization: CodeGenFeatureStatus) {
        switch initializationType {
        case .original:
            generateOriginalOperationsContextGenerator(generationType: generationType,
                                                       contextTypeName: contextTypeName,
                                                       mainAnnotation: mainAnnotation)
        case .streamlined:
            generateStreamlinedOperationsContextGenerator(generationType: generationType,
                                                          contextTypeName: contextTypeName,
                                                          mainAnnotation: mainAnnotation,
                                                          asyncInitialization: asyncInitialization)
        }
    }
    
    private func generateOriginalOperationsContextGenerator(generationType: GenerationType,
                                                            contextTypeName: String,
                                                            mainAnnotation: CodeGenFeatureStatus) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        let fileName = "\(baseName)PerInvocationContextInitializer.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if generationType.isUpdate {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)PerInvocationContextInitializer.swift
            // \(baseName)\(applicationSuffix)
            //
            
            import \(baseName)Model
            import \(baseName)Operations
            import \(http1IntegrationTargetName)
            import SmokeHTTP1
            import SmokeOperationsHTTP1
            import SmokeOperationsHTTP1Server
            import AWSCore
            import NIO
            
            typealias \(baseName)OperationDelegate = JSONPayloadHTTP1OperationDelegate<SmokeInvocationTraceContext>
            
            /**
             Initializer for the \(baseName)\(applicationSuffix).
             */
            """)
        
        if case .enabled = mainAnnotation {
            fileBuilder.appendLine("""
                @main
                """)
        }
        
        fileBuilder.appendLine("""
            struct \(baseName)PerInvocationContextInitializer: SmokeServerPerInvocationContextInitializer {
                typealias SelectorType =
                    StandardSmokeHTTP1HandlerSelector<\(contextTypeName), \(baseName)OperationDelegate,
                                                      \(baseName)ModelOperations>
            
                let handlerSelector: SelectorType
            
                // TODO: Add properties to be accessed by the operation handlers
            
                /**
                 On application startup.
                 */
                init(eventLoopGroup: EventLoopGroup) throws {
                    CloudwatchStandardErrorLogger.enableLogging()
            
                    var selector = SelectorType(defaultOperationDelegate: JSONPayloadHTTP1OperationDelegate())
                    addOperations(selector: &selector)
            
                    self.handlerSelector = selector
                }
            
                /**
                 On invocation.
                */
                public func getInvocationContext(invocationReporting: SmokeServerInvocationReporting<SmokeInvocationTraceContext>)
                -> \(contextTypeName) {
                    return \(contextTypeName)(logger: invocationReporting.logger)
                }
            
                /**
                 On application shutdown.
                */
                func onShutdown() throws {
                    
                }
            
                static func main() throws {
                    SmokeHTTP1Server.runAsOperationServer(Self.init)
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
    
    private func generateStreamlinedOperationsContextGenerator(generationType: GenerationType,
                                                               contextTypeName: String,
                                                               mainAnnotation: CodeGenFeatureStatus,
                                                               asyncInitialization: CodeGenFeatureStatus) {
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        let fileName = "\(baseName)PerInvocationContextInitializer.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if generationType.isUpdate {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)PerInvocationContextInitializer.swift
            // \(baseName)\(applicationSuffix)
            //
            
            import \(baseName)Operations
            import \(http1IntegrationTargetName)
            import SmokeOperationsHTTP1Server
            import AWSCore
            import NIO
                        
            /**
             Initializer for the \(baseName)\(applicationSuffix).
             */
            """)
        
        if case .enabled = mainAnnotation {
            fileBuilder.appendLine("""
                @main
                """)
        }
        
        let asyncPrefix: String
        switch asyncInitialization {
        case .disabled:
            asyncPrefix = ""
        case .enabled:
            asyncPrefix = "async "
        }
        
        fileBuilder.appendLine("""
            struct \(baseName)PerInvocationContextInitializer: \(baseName)PerInvocationContextInitializerProtocol {
                // TODO: Add properties to be accessed by the operation handlers
            
                /**
                 On application startup.
                 */
                init(eventLoopGroup: EventLoopGroup) \(asyncPrefix)throws {
                    CloudwatchStandardErrorLogger.enableLogging()
            
                    // TODO: Add additional application initialization
                }
            
                /**
                 On invocation.
                */
                public func getInvocationContext(invocationReporting: SmokeServerInvocationReporting<SmokeInvocationTraceContext>)
                -> \(contextTypeName) {
                    return \(contextTypeName)(logger: invocationReporting.logger)
                }
            
                /**
                 On application shutdown.
                */
                func onShutdown() \(asyncPrefix)throws {
                    
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
    
    public func generateStreamlinedOperationsContextProtocolGenerator(generationType: GenerationType,
                                                                      contextTypeName: String,
                                                                      asyncInitialization: CodeGenFeatureStatus) {
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        let fileName = "\(baseName)PerInvocationContextInitializerProtocol.swift"
        let filePath = "\(baseFilePath)/Sources/\(http1IntegrationTargetName)"
        
        let baseInitializerInfix: String
        let asyncPrefix: String
        let awaitPrefix: String
        switch asyncInitialization {
        case .disabled:
            baseInitializerInfix = ""
            asyncPrefix = ""
            awaitPrefix = ""
        case .enabled:
            baseInitializerInfix = "Async"
            asyncPrefix = "async "
            awaitPrefix = "await "
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)PerInvocationContextInitializerProtocol.swift
            // \(http1IntegrationTargetName)
            //
            
            import \(baseName)Model
            import \(baseName)Operations
            import NIO
            import SmokeHTTP1
            import SmokeOperationsHTTP1Server
                        
            /**
             Convenience protocol for the initialization of \(baseName)\(applicationSuffix).
             */
            public protocol \(baseName)PerInvocationContextInitializerProtocol: StandardJSONSmoke\(baseInitializerInfix)ServerPerInvocationContextInitializer
            where ContextType == \(contextTypeName), OperationIdentifer == \(baseName)ModelOperations {
                init(eventLoopGroup: EventLoopGroup) \(asyncPrefix)throws
            }
            
            public extension \(baseName)PerInvocationContextInitializerProtocol {
                // specify how to initalize the server with operations
                var operationsInitializer: OperationsInitializerType {
                    return \(baseName)ModelOperations.addToSmokeServer
                }
            
                var serverName: String {
                    return "\(baseName)\(applicationSuffix)"
                }
            
                static func main() \(asyncPrefix)throws {
                    \(awaitPrefix)SmokeHTTP1Server.runAsOperationServer(Self.init)
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
