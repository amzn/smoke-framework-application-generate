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

extension ServiceModelCodeGenerator {
    /**
     Generate the stub operations context generator for the generated application.
     */
    func generateOperationsContextGenerator(generationType: GenerationType,
                                            initializationType: InitializationType) {
        switch initializationType {
        case .original:
            generateOriginalOperationsContextGenerator(generationType: generationType)
        case .streamlined:
            generateStreamlinedOperationsContextGenerator(generationType: generationType)
        }
    }
    
    private func generateOriginalOperationsContextGenerator(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "\(baseName)PerInvocationContextInitializer.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if case .serverUpdate = generationType {
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
            import \(baseName)OperationsHTTP1
            import SmokeOperationsHTTP1
            import SmokeOperationsHTTP1Server
            import SmokeAWSCore
            import NIO
            
            typealias \(baseName)OperationDelegate = JSONPayloadHTTP1OperationDelegate<SmokeInvocationTraceContext>
            
            /**
             Initializer for the \(baseName)\(applicationSuffix).
             */
            struct \(baseName)PerInvocationContextInitializer: SmokeServerPerInvocationContextInitializer {
                typealias SelectorType =
                    StandardSmokeHTTP1HandlerSelector<\(baseName)OperationsContext, \(baseName)OperationDelegate,
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
                -> \(baseName)OperationsContext {
                    return \(baseName)OperationsContext(logger: invocationReporting.logger)
                }
            
                /**
                 On application shutdown.
                */
                func onShutdown() throws {
                    
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
    
    private func generateStreamlinedOperationsContextGenerator(generationType: GenerationType) {
        generateStreamlinedOperationsContextProtocolGenerator(generationType: generationType)
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "\(baseName)PerInvocationContextInitializer.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if case .serverUpdate = generationType {
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
            import \(baseName)OperationsHTTP1
            import SmokeOperationsHTTP1Server
            import SmokeAWSCore
            import NIO
                        
            /**
             Initializer for the \(baseName)\(applicationSuffix).
             */
            struct \(baseName)PerInvocationContextInitializer: \(baseName)PerInvocationContextInitializerProtocol {
                // TODO: Add properties to be accessed by the operation handlers
            
                /**
                 On application startup.
                 */
                init(eventLoopGroup: EventLoopGroup) throws {
                    CloudwatchStandardErrorLogger.enableLogging()
            
                    // TODO: Add additional application initialization
                }
            
                /**
                 On invocation.
                */
                public func getInvocationContext(invocationReporting: SmokeServerInvocationReporting<SmokeInvocationTraceContext>)
                -> \(baseName)OperationsContext {
                    return \(baseName)OperationsContext(logger: invocationReporting.logger)
                }
            
                /**
                 On application shutdown.
                */
                func onShutdown() throws {
                    
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
    
    private func generateStreamlinedOperationsContextProtocolGenerator(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "\(baseName)PerInvocationContextInitializerProtocol.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1"
        
        fileBuilder.appendLine("""
            //
            // \(baseName)PerInvocationContextInitializerProtocol.swift
            // \(baseName)OperationsHTTP1
            //
            
            import \(baseName)Model
            import \(baseName)Operations
            import SmokeOperationsHTTP1Server
                        
            /**
             Convenience protocol for the initialization of \(baseName)\(applicationSuffix).
             */
            public protocol \(baseName)PerInvocationContextInitializerProtocol: StandardJSONSmokeServerPerInvocationContextInitializer
            where ContextType == \(baseName)OperationsContext, OperationIdentifer == \(baseName)ModelOperations {

            }
            
            public extension \(baseName)PerInvocationContextInitializerProtocol {
                // specify how to initalize the server with operations
                var operationsInitializer: OperationsInitializerType {
                    return \(baseName)ModelOperations.addToSmokeServer
                }
            
                var serverName: String {
                    return "\(baseName)\(applicationSuffix)"
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
