import PackagePlugin
import Foundation

private let targetSuffix = "Client"

@main
struct SmokeFrameworkGenerateClientPlugin: BuildToolPlugin {
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
        
        let inputFile = context.package.directory.appending("smoke-framework-codegen.json")
        
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = clientOutputPaths

        // Construct the command arguments.
        let commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenClient"
        ]

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating client files",
            executable: smokeFrameworkApplicationGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
    }
}
