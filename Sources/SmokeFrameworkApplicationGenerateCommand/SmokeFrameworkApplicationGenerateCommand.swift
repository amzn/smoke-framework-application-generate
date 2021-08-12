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
            initializationType: config?.initializationType,
            operationStubGenerationRule: operationStubGenerationRule,
            swaggerFileVersion: theSwaggerVersion)
        
        try handleApplication(parameters: parameters)
    }
}


