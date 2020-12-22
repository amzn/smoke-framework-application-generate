// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

var isUsage = CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--help"

struct Options {
    static let modelFilePathOption = "--model-path"
    static let baseNameOption = "--base-name"
    static let applicationSuffixOption = "--application-suffix"
    static let baseFilePathOption = "--base-file-path"
    static let generationTypeOption = "--generation-type"
    static let applicationDescriptionOption = "--application-description"
    static let modelOverridePathOption = "--model-override-path"
    static let httpClientConfigurationPathOption = "--http-client-configuration-path"
}

struct Parameters {
    var modelFilePath: String?
    var baseName: String?
    var applicationSuffix: String = "Service"
    var baseFilePath: String?
    var generationType: GenerationType?
    var applicationDescription: String?
    var modelOverridePath: String?
    var httpClientConfigurationPath: String?
}

func printUsage() {
    let usage = """
        OVERVIEW: Generate a swift package based on a Swagger Model.

        USAGE: SmokeFrameworkApplicationGenerate [options]

        OPTIONS:
          --model-path         The file path for the model definition.
          --base-name          The base name for the generated libraries and executable.
                               The generate executable will have the name-
                                 <base-name><application-suffix>.
                               Libraries for the application will have names-
                                 <base-name><generator-defined-library-type-name>
          --application-suffix The suffix for the generated executable [Service].
          --base-file-path     The file path to place the root of the generated Swift package.
          --generation-type    What code to generate. (server|serverUpdate)
          [--application-description]
                               A description of the application being created.
          [--model-override-path]
                               The file path to model override parameters.
          [--http-client-configuration-path]
                               The file path to the configuration for the http client.
                               If not specified, the http client will consider all
                               known errors as unretryable and all unknown errors as
                               unretryable.
        """

    print(usage)
}

private func getModelOverride(modelOverridePath: String?) throws -> ModelOverride? {
    let modelOverride: ModelOverride?
    if let modelOverridePath = modelOverridePath {
        let overrideFile = FileHandle(forReadingAtPath: modelOverridePath)
        
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(modelOverridePath) doesn't exist.'")
        }
        
        modelOverride = try JSONDecoder().decode(ModelOverride.self, from: overrideData)
    } else {
        modelOverride = nil
    }
    
    return modelOverride
}

private func updateParametersFromOption(
        option: String, parameters: inout Parameters,
        argument: String, errorMessage: inout String?) {
    switch option {
    case Options.modelFilePathOption:
        parameters.modelFilePath = argument
    case Options.baseNameOption:
        parameters.baseName = argument
    case Options.applicationSuffixOption:
        parameters.applicationSuffix = argument
    case Options.baseFilePathOption:
        parameters.baseFilePath = argument
    case Options.modelOverridePathOption:
        parameters.modelOverridePath = argument
    case Options.httpClientConfigurationPathOption:
        parameters.httpClientConfigurationPath = argument
    case Options.applicationDescriptionOption:
        parameters.applicationDescription = argument
    case Options.generationTypeOption:
        if let newGenerationType = GenerationType(rawValue: argument.lowercased()) {
            parameters.generationType = newGenerationType
        } else {
            errorMessage = "Unrecognized generation type: \(argument)"
            
            break
        }
    default:
        errorMessage = "Unrecognized option: \(option)"
    }
}

private func getOptions(missingOptions: inout Set<String>,
                        parameters: inout Parameters,
                        errorMessage: inout String?) {
    var currentOption: String?
    for argument in CommandLine.arguments.dropFirst() {
        if currentOption == nil && argument.hasPrefix("--") {
            currentOption = argument
            missingOptions.remove(argument)
        } else if let option = currentOption, !argument.hasPrefix("--") {
            updateParametersFromOption(option: option, parameters: &parameters,
                                       argument: argument, errorMessage: &errorMessage)
            
            currentOption = nil
        } else {
            printUsage()
            
            break
        }
        
    }
}

private func getHttpClientConfiguration(httpClientConfigurationPath: String?) throws
-> HttpClientConfiguration {
    let httpClientConfiguration: HttpClientConfiguration
    if let httpClientConfigurationPath = httpClientConfigurationPath {
        let overrideFile = FileHandle(forReadingAtPath: httpClientConfigurationPath)
        
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(httpClientConfigurationPath) doesn't exist.'")
        }
        
        httpClientConfiguration = try JSONDecoder().decode(HttpClientConfiguration.self,
                                                           from: overrideData)
    } else {
        httpClientConfiguration = HttpClientConfiguration(
            retryOnUnknownError: true,
            knownErrorsDefaultRetryBehavior: .fail,
            unretriableUnknownErrors: [],
            retriableUnknownErrors: [])
    }
    
    return httpClientConfiguration
}

private func startCodeGeneration(
        httpClientConfiguration: HttpClientConfiguration,
        baseName: String, baseFilePath: String,
        applicationDescription: String, applicationSuffix: String,
        modelFilePath: String, generationType: GenerationType,
        modelOverride: ModelOverride?) throws {
    let validationErrorDeclaration = ErrorDeclaration.external(
        libraryImport: "SmokeOperations",
        errorType: "SmokeOperationsError")
    let unrecognizedErrorDeclaration = ErrorDeclaration.internal
    let customizations = CodeGenerationCustomizations(
        validationErrorDeclaration: validationErrorDeclaration,
        unrecognizedErrorDeclaration: unrecognizedErrorDeclaration,
        generateModelShapeConversions: true,
        optionalsInitializeEmpty: true,
        fileHeader: nil,
        httpClientConfiguration: httpClientConfiguration)
    
    let fullApplicationDescription = ApplicationDescription(
        baseName: baseName,
        baseFilePath: baseFilePath,
        applicationDescription: applicationDescription,
        applicationSuffix: applicationSuffix)
    
    try SmokeFrameworkCodeGeneration.generateFromModel(
        modelFilePath: modelFilePath,
        modelType: SwaggerServiceModel.self,
        generationType: generationType,
        customizations: customizations,
        applicationDescription: fullApplicationDescription,
        modelOverride: modelOverride)
}

func handleApplication() throws {
    var errorMessage: String?

    var missingOptions: Set<String> = [Options.modelFilePathOption, Options.baseNameOption,
                                       Options.baseFilePathOption, Options.generationTypeOption]

    var parameters = Parameters()
    getOptions(missingOptions: &missingOptions,
               parameters: &parameters, errorMessage: &errorMessage)

    let modelOverride = try getModelOverride(modelOverridePath: parameters.modelOverridePath)

    let httpClientConfiguration = try getHttpClientConfiguration(
        httpClientConfigurationPath: parameters.httpClientConfigurationPath)

    // If there is not an application description but there is a basename
    if parameters.applicationDescription == nil,
        let baseName = parameters.baseName {
        parameters.applicationDescription = "The \(baseName)\(parameters.applicationSuffix)."
    }

    if errorMessage == nil {
        if let modelFilePath = parameters.modelFilePath,
            let baseName = parameters.baseName,
            let baseFilePath = parameters.baseFilePath,
            let applicationDescription = parameters.applicationDescription,
            let generationType = parameters.generationType {
                try startCodeGeneration(
                    httpClientConfiguration: httpClientConfiguration,
                    baseName: baseName, baseFilePath: baseFilePath,
                    applicationDescription: applicationDescription,
                    applicationSuffix: parameters.applicationSuffix, modelFilePath: modelFilePath,
                    generationType: generationType, modelOverride: modelOverride)
        } else {
            var missingOptionsString: String = ""
            missingOptions.forEach { option in missingOptionsString += " " + option }

            errorMessage = "Missing required options:" + missingOptionsString
        }
    }

    if let errorMessage = errorMessage {
        print("ERROR: \(errorMessage)\n")

        printUsage()
    }
}

if isUsage {
    printUsage()
} else {
    try handleApplication()
}
