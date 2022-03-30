import PackagePlugin
import Foundation

private let targetSuffix = "Model"

@main
struct SmokeFrameworkGenerateModelPlugin: BuildToolPlugin {
    /// This plugin's implementation returns a single build command which
    /// calls `SmokeFrameworkApplicationGenerate` to generate the service model.
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // get the generator tool
        let smokeFrameworkApplicationGenerateTool = try context.tool(named: "SmokeFrameworkApplicationGenerate")
        let sourcesDirectory = context.pluginWorkDirectory.appending("Sources")
        
        var baseName = target.name
        if baseName.hasSuffix(targetSuffix) {
            baseName = String(baseName.dropLast(targetSuffix.count))
        }
        
        let modelDirectory = sourcesDirectory.appending("\(baseName)\(targetSuffix)")
        
        let modelFiles = ["\(baseName)\(targetSuffix)Errors.swift",
                          "\(baseName)\(targetSuffix)Structures.swift",
                          "\(baseName)\(targetSuffix)DefaultInstances.swift",
                          "\(baseName)\(targetSuffix)Operations.swift",
                          "\(baseName)\(targetSuffix)Types.swift"]
        let modelOutputPaths = modelFiles.map { modelDirectory.appending($0) }
        
        let inputFile = context.package.directory.appending("smoke-framework-codegen.json")
        
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = modelOutputPaths

        // Construct the command arguments.
        let commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenModel"
        ]

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating model files",
            executable: smokeFrameworkApplicationGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
    }
}
