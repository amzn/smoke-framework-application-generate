<p align="center">
<a href="https://github.com/amzn/smoke-framework-application-generate/actions">
<img src="https://github.com/amzn/smoke-framework-application-generate/actions/workflows/swift.yml/badge.svg?branch=main" alt="Build - main Branch">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.4|5.5|5.6-orange.svg?style=flat" alt="Swift 5.4, 5.5 and 5.6 Tested">
</a>
<a href="https://gitter.im/SmokeServerSide">
<img src="https://img.shields.io/badge/chat-on%20gitter-ee115e.svg?style=flat" alt="Join the Smoke Server Side community on gitter">
</a>
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>

# SmokeFrameworkApplicationGenerate

Code generator to generate [SmokeFramework](https://github.com/amzn/smoke-framework)-based applications from service models.

# Generate a SmokeFramework application package from a Swagger 2.0 specification file

## Step 1: Check out this repository

Clone this repository to your local machine.

## Step 2: Create a new directory in which to create your service.

You will point this code generator to this directory to output the generated code.

## Step 3: Create a model describing your service using Swagger 2.0

Follow the [Swagger specification](https://swagger.io/docs/specification/2-0/basic-structure/) to create an API specification for your service.
Place this file in the directory you have created. The following steps assume you have called this file `Swagger.yaml` but it
can be called anything you require.

## Step 4: Create a configuration file for the code generator

Create a `smoke-framework-codegen.json` file in the directory you have created with the following content-

```
{
  "baseName" : "EmptyExample",
  "modelFilePath" : "OpenAPI30.yaml",
  "modelFormat" : "OPENAPI3_0",
  "generationType" : "serverUpdateWithPlugin",
  "initializationType": "STREAMLINED",
  "testDiscovery": "ENABLED",
  "mainAnnotation": "ENABLED",
  "asyncAwait": {
    "clientAPIs": "ENABLED",
    "asyncOperationStubs": "ENABLED",
    "asyncInitialization": "ENABLED"
  },
  "operationStubGenerationRule" : {
    "mode" : "allFunctionsWithinContext"
  }
}
```

This JSON file can contain the following fields-
* **modelFilePath**: Specifies the absolute or relative (to the base directory path) file path to the Swagger model. Required.
* **modelFormat**: Specifies the format of the provided model. `OPENAPI3_0` indicates Open API 3.0 and `SWAGGER` indicates a Swagger 2.0 model. Optional, defaults to `Swagger`.
* **baseName**: A base name for your service (without the "Service" postfix). Required.
* **applicationSuffix**: The suffix that is combined with the `baseName` to create the service's executable name. Defaults to `Service`.
* **generationType**: `server` to generate a new service; `serverUpdateWithPlugin` to preserve changes to existing operation handlers while using this generator during the build process to generate model and client files. Required.
* **applicationDescription**: A description of the application. Optional.
* **modelOverride**: A set of overrides to apply to the model. Optional.
* **initializationType**: `STREAMLINED` is recommended and uses a code generated initializer protocol to reduce the manual setup required. `ORIGINAL` requires additional manual initialization. Optional; defaulting to `ORIGINAL` for legacy applications.
* **testDiscovery**: `ENABLED` is recommended and will not generate `LinuxMain.swift` and associated TestCase lists. `DISABLED` will code generate these. Optional; defaulting to `DISABLED` for legacy applications.
* **mainAnnotation**: `ENABLED` is recommended and will not generate `main.swift` and will instead specify the @main annotation on the application initializer. `DISABLED` will code generate `main.swift`. Optional; defaulting to `DISABLED` for legacy applications.
* **asyncAwait**: Specifies if 1) async client APIs will be generated, 2) operation handler stubs will be code generated as async methods and 3) if the initialization and shutdown methods can be async methods (and will code generated as such if they don't exist). Optional; by default `clientAPIs` and `asyncOperationStubs` will be enabled but `asyncInitialization` will be disabled for legacy applications. 
* **eventLoopFutureOperationHandlers**: `ENABLED` will support the use of `EventLoopFuture`-returning operation handlers. Integration for these types of handlers are contained in the `SmokeAsyncHTTP1` product of the `smoke-framework` package. A dependency on this product will need to be added to the `\(applicationBaseName)OperationsHTTP1` product of the code generated application if this option is enabled. Optional, disabled by default.
* **httpClientConfiguration**: Configuration for the generated http service clients. Optional.
* **operationStubGenerationRule**: How operation stubs are generated and expected by the application. It is recommended that new applications use `allFunctionsWithinContext` which will generate operation stubs within extensions of the Context type[1].

The schemas for the `modelOverride` and `httpClientConfiguration` fields can be found here - https://github.com/amzn/service-model-swift-code-generate/blob/main/Sources/ServiceModelEntities/ModelOverride.swift.

An example configuration - including `modelOverride` configuration - can be found here - https://github.com/amzn/smoke-framework-examples/blob/612fd9dca5d8417d2293a203aca4b02672889d12/PersistenceExampleService/smoke-framework-codegen.json.

[1] Existing smoke-framework based applications may have operation handlers that are standalone functions. You can use the `allStandaloneFunctions` value for `operationStubGenerationRule` to continue this style or migrate the operation handlers - either at once or one-by-one - to being functions on the Context type. See the Migration section at the end of this README for more information.

## Step 4: Run the code generator

From within your checked out copy of this repository, run this command-

```bash
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path <the path to where you want the service to be generated>
```

An example command would look like this-

```bash
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService
```

An example service based on the command above can be found [here](https://github.com/amzn/smoke-framework-examples/tree/main/PersistenceExampleService).

# Step 5: Modify the stubbed service generated

The code generator will produce a Swift Package Manager repository with the following directory structure-

```bash
- Package.swift
- .swiftlint
- .gitignore
- Sources
  - (base-name)Client[1]
  - (base-name)Model[1]
  - (base-name)Operations
  - (base-name)OperationsHTTP1[1]
  - (base-name)Service
- Tests
  - LinuxMain.swift      
  - <base-name>OperationsTests
```

The following three sections of the repository provides initial stubs and can be filled out as required for the service.  
A `generationType` of `serverUpdate` will not overwrite changes in these sections-

* **(base-name)Operations:** Stub implementations for each operation; should be modified to fullfill the services's logic.
* **(base-name)OperationsTests:** Stub test implementations for each operation; should be modified to test the services's logic.
* **(base-name)Service:** Operations context initialization and shutdown code; should be modified to create the context for the current environment.

The following three section contain code generated code to help the service operate but should not be manually modified. 
A `generationType` of `serverUpdate` will overwrite changes in these sections-

* **(base-name)Client:** APIGateway and mock clients for the service; should not be manually modified.
* **(base-name)Client:** Input and output structures and types for the service; should not be manually modified.
* **(base-name)Client:** Operation selection and input/output type handling specific to HTTP1; should not be manually modified.

[1] In the default configuration, the full contents of these packages will be generated during the build process.

# Migration to using smoke-framework-codegen.json

## smoke-framework-codegen.json generation

Existing smoke-framework based applications may not have been generated by using a `smoke-framework-codegen.json` file. Moving
to a single configuration file is intended to simplify the code generation process and to prepare the way for code generation as part
of the build process.

You can easily generate the configuration file by adding the `--generate-code-gen-config true` flag to the command previously used to generate the service.

```
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path <the path to where you want the service to be generated> \
  --base-name <a base name for your service (without the "Service" postfix)> \
  --model-path <the path to the Swagger model you created> \
  --generate-code-gen-config true \
  --generation-type [server: to generate a new service|serverUpdate: to preserve changes to existing operation handlers]
 [--model-override-path <optionally the path to a json file that specifies various overrides to the model>]
```

An example command would look like this-

```
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService \
  --base-name PersistenceExample \
  --model-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService/Swagger.yaml \
  --generate-code-gen-config true \
  --generation-type server \
  --model-override-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService/modelOverride.json
```

The generated `smoke-framework-codegen.json` file will specify an `operationStubGenerationRule` of `allFunctionsWithinContextExceptForSpecifiedStandaloneFunctions`  with all current operations listed under `operationsWithStandaloneFunctions`. The means that by default the migration will require no change to any existing operation handlers
but any new operations will have handlers generated within extensions of the Context type. 

## Operation stub generation

It is also possible to change where the generated application expects an operation handler to be - either a standalone function or a function
on the Context type. Migration of operation handlers is entirely optional and can be done if you find this style more convenient.

To *migrate* an existing operation with a standalone handler function to the Context type, remove the operation from the `operationsWithStandaloneFunctions` list and manually move the operation handler function
to an extension of the Content type, also removing the explicit context parameter to the function.

For example, an existing operation handler-

```
public func handleGetCustomerDetails(
        input: EmptyExampleModel.GetCustomerDetailsRequest,
        context: EmptyExampleOperationsContext) throws -> EmptyExampleModel.CustomerAttributes {
    ...
}
```

would be migrated to-

```
extension EmptyExampleOperationsContext {
    public func handleGetCustomerDetails(input: EmptyExampleModel.GetCustomerDetailsRequest) throws
    -> EmptyExampleModel.CustomerAttributes {
        ...
    }
}
```

# Migration to using the generator as an SPM Plugin

Starting with Swift 5.6, this generator can be used during the build process to avoid having to check the fully code-generated model, client and http1 integration files into the source repository. This section describes the steps to migrate a Smoke-framework based application to using this generator as a plugin.

## Step 1: Use build tools 5.6

In order to use this generator as an SPM plugin, the application will have to use Swift tools version 5.6 and at compile with at least the Swift 5.6 compiler. At the top of the application's `Package.swift` manifest, make sure the correct Swift tools version is specified.

```
// swift-tools-version:5.6
```

## Step 2: Add a dependency on this generator

Still in the `Package.swift` manifest, add a dependency on this package.

```
.package(url: "https://github.com/amzn/smoke-framework-application-generate", from: "3.0.0-beta.1")
```

## Step 3: Specific plugs for the Model, Client and Http1 Integration packages

Still in the `Package.swift` manifest, add plugin declarations for the model, client and Http1 Integration packages. For example

For the Model package-

```
.target(
    name: "EmptyExampleModel", dependencies: [
        .product(name: "SmokeOperations", package: "smoke-framework"),
        .product(name: "Logging", package: "swift-log"),
    ],
    plugins: [
        .plugin(name: "SmokeFrameworkGenerateModel", package: "smoke-framework-application-generate")
    ]
),
```

For the Client package-

```
.target(
    name: "EmptyExampleClient", dependencies: [
        .target(name: "EmptyExampleModel"),
        .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
        .product(name: "SmokeAWSHttp", package: "smoke-aws"),
    ],
    plugins: [
        .plugin(name: "SmokeFrameworkGenerateClient", package: "smoke-framework-application-generate")
    ]
),
```

For the Http1 Integration package-

```
.target(
    name: "EmptyExampleOperationsHTTP1", dependencies: [
        .target(name: "EmptyExampleOperations"),
        .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
        .product(name: "SmokeOperationsHTTP1Server", package: "smoke-framework"),
    ],
    plugins: [
        .plugin(name: "SmokeFrameworkGenerateHttp1", package: "smoke-framework-application-generate")
    ]
),
```

## Step 4: Delete existing files in these packages

Delete the previously generated files in the Model, Client and Http1 Integration packages. These will now be generated at compile time using this generator.

## Step 5: Add a placeholder file in these packages

Due to a current limitation of the SPM plugins for code generators, a placeholder Swift file is required in each package to avoid the package as being seen as empty. These files need to be a Swift file but doesn't require any particular contents.

## License

This library is licensed under the Apache 2.0 License.
