import PackagePlugin
import Foundation

private let targetSuffix = "OperationsHTTP1"

enum PluginError: Error {
    case unknownModelPackageDependency(packageName: String)
    case unknownModelTargetDependency(packageName: String, targetName: String)
    case sourceModuleTargetRequired(packageName: String, targetName: String, type: Target.Type)
    case unknownModelFilePath(packageName: String, targetName: String, fileName: String)
}

@main
struct SmokeFrameworkGenerateHttp1Plugin: BuildToolPlugin {
    struct SmokeFrameworkCodeGen: Codable {
        let modelProductDependency: String?
        let modelTargetDependency: String?
        let modelFilePath: String
    }
    
    /// This plugin's implementation returns a single build command which
    /// calls `SmokeFrameworkApplicationGenerate` to generate the http1 protocol integration.
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // get the generator tool
        let smokeFrameworkApplicationGenerateTool = try context.tool(named: "SmokeFrameworkApplicationGenerate")
        let sourcesDirectory = context.pluginWorkDirectory.appending("Sources")
        
        var baseName = target.name
        if baseName.hasSuffix(targetSuffix) {
            baseName = String(baseName.dropLast(targetSuffix.count))
        }
        
        let inputFile = context.package.directory.appending("smoke-framework-codegen.json")
        
        let modelFilePathOverride = try getModelFilePathOverride(target: target, configFilePath: inputFile.string)

        let http1Directory = sourcesDirectory.appending("\(baseName)\(targetSuffix)")
        
        let http1Files = ["\(baseName)OperationsHTTPInput.swift",
                          "\(baseName)OperationsHanderSelector.swift",
                          "\(baseName)OperationsHTTPOutput.swift",
                          "\(baseName)PerInvocationContextInitializerProtocol.swift"]
        let http1OutputPaths = http1Files.map { http1Directory.appending($0) }
                
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = http1OutputPaths

        // Construct the command arguments.
        var commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenHttp1"
        ]
        
        if let modelFilePathOverride = modelFilePathOverride {
            commandArgs.append(contentsOf: ["--model-path", modelFilePathOverride])
        }

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating HTTP1 integration files",
            executable: smokeFrameworkApplicationGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
    }
    
    private func getModelFilePathOverride(target: Target, configFilePath: String) throws -> String? {
        let configFile = FileHandle(forReadingAtPath: configFilePath)
        
        let config: SmokeFrameworkCodeGen?
        if let configData = configFile?.readDataToEndOfFile() {
            config = try JSONDecoder().decode(SmokeFrameworkCodeGen.self, from: configData)
        } else {
            config = nil
        }
                
        // if the model is in a dependency
        if let config = config, let modelProductDependency = config.modelProductDependency {
            let dependencies: [Product] = target.dependencies.compactMap { dependency in
                if case .product(let product) = dependency, product.name == modelProductDependency {
                    return product
                }
                
                return nil
            }
            
            // if there is no such dependency
            guard let modelProduct = dependencies.first else {
                throw PluginError.unknownModelPackageDependency(packageName: modelProductDependency)
            }
            
            let modelTargetDependency = config.modelTargetDependency ?? modelProductDependency
            
            let filteredTargets = modelProduct.targets.filter { $0.name == modelTargetDependency }
            guard let modelTarget = filteredTargets.first else {
                throw PluginError.unknownModelTargetDependency(packageName: modelProductDependency,
                                                               targetName: modelTargetDependency)
            }
            
            guard let modelTarget = modelTarget as? SourceModuleTarget else {
                throw PluginError.sourceModuleTargetRequired(packageName: modelProductDependency,
                                                             targetName: modelTargetDependency,
                                                             type: type(of: modelTarget))
            }
            
            let targetDirectory: String
            let rawTargetDirectory = modelTarget.directory.string
            if !rawTargetDirectory.hasSuffix("/") {
                targetDirectory = "\(rawTargetDirectory)/"
            } else {
                targetDirectory = rawTargetDirectory
            }
                  
            let filteredFiles = modelTarget.sourceFiles.filter { $0.path.string.dropFirst(targetDirectory.count) == config.modelFilePath }
            guard let modelFile = filteredFiles.first else {
                throw PluginError.unknownModelFilePath(packageName: modelProductDependency,
                                                       targetName: modelTargetDependency,
                                                       fileName: config.modelFilePath)
            }
            
            return modelFile.path.string
        }
        
        return nil
    }
}
