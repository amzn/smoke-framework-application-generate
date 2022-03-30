import PackagePlugin
import Foundation

private let targetSuffix = "OperationsHTTP1"

@main
struct SmokeFrameworkGenerateHttp1Plugin: BuildToolPlugin {
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

        let http1Directory = sourcesDirectory.appending("\(baseName)\(targetSuffix)")
        
        let http1Files = ["\(baseName)OperationsHTTPInput.swift",
                          "\(baseName)OperationsHanderSelector.swift",
                          "\(baseName)OperationsHTTPOutput.swift",
                          "\(baseName)PerInvocationContextInitializerProtocol.swift"]
        let http1OutputPaths = http1Files.map { http1Directory.appending($0) }
        
        let inputFile = context.package.directory.appending("smoke-framework-codegen.json")
        
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = http1OutputPaths

        // Construct the command arguments.
        let commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenHttp1"
        ]

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating HTTP1 integration files",
            executable: smokeFrameworkApplicationGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
    }
}
