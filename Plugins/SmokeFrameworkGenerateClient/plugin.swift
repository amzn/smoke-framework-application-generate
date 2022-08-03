import PackagePlugin
import Foundation

private let targetSuffix = "Client"

enum PluginError: Error {
    case unknownModelPackageDependency(packageName: String)
    case unknownModelTargetDependency(packageName: String, targetName: String)
    case sourceModuleTargetRequired(packageName: String, targetName: String, type: Target.Type)
    case unknownModelFilePath(packageName: String, targetName: String, fileName: String)
}

@main
struct SmokeFrameworkGenerateClientPlugin: BuildToolPlugin {
    struct SmokeFrameworkCodeGen: Codable {
        let modelProductDependency: String?
        let modelTargetDependency: String?
        let modelFilePath: String
    }
    
    /// This plugin's implementation returns a single build command which
    /// calls `SmokeFrameworkApplicationGenerate` to generate the service client.
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
        
        let clientDirectory = sourcesDirectory.appending("\(baseName)\(targetSuffix)")
        
        let clientFiles = ["APIGateway\(baseName)\(targetSuffix).swift",
                           "\(baseName)\(targetSuffix)Protocol.swift",
                           "\(baseName)Operations\(targetSuffix)Output.swift",
                           "APIGateway\(baseName)\(targetSuffix)Generator.swift",
                           "\(baseName)InvocationsReporting.swift",
                           "\(baseName)OperationsReporting.swift",
                           "Mock\(baseName)\(targetSuffix).swift",
                           "\(baseName)Operations\(targetSuffix)Input.swift",
                           "Throwing\(baseName)\(targetSuffix).swift"]
        let clientOutputPaths = clientFiles.map { clientDirectory.appending($0) }
        
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = clientOutputPaths

        // Construct the command arguments.
        var commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenClient"
        ]
        
        if let modelFilePathOverride = modelFilePathOverride {
            commandArgs.append(contentsOf: ["--model-path", modelFilePathOverride])
        }

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating client files",
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
