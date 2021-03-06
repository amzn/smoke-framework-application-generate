<p align="center">
<a href="https://travis-ci.com/amzn/smoke-framework-application-generate">
<img src="https://travis-ci.com/amzn/smoke-framework-application-generate.svg?branch=master" alt="Build - Master Branch">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.2|5.3|5.4-orange.svg?style=flat" alt="Swift 5.2, 5.3 and 5.4 Tested">
</a>
<img src="https://img.shields.io/badge/ubuntu-16.04|18.04|20.04-yellow.svg?style=flat" alt="Ubuntu 16.04, 18.04 and 20.04 Tested">
<img src="https://img.shields.io/badge/CentOS-8-yellow.svg?style=flat" alt="CentOS 8 Tested">
<img src="https://img.shields.io/badge/AmazonLinux-2-yellow.svg?style=flat" alt="Amazon Linux 2 Tested">
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
  "modelFilePath" : "Swagger.yaml",
  "generationType" : "serverUpdate",
  "operationStubGenerationRule" : {
    "mode" : "allFunctionsWithinContext"
  }
}
```

This JSON file can contain the following fields-
* **modelFilePath**: Specifies the absolute or relative (to the base directory path) file path to the Swagger model. Required.
* **baseName**: A base name for your service (without the "Service" postfix). Required.
* **applicationSuffix**: The suffix that is combined with the `baseName` to create the service's executable name. Defaults to `Service`.
* **generationType**: `server` to generate a new service; `serverUpdate` to preserve changes to existing operation handlers. Required.
* **applicationDescription**: A description of the application. Optional.
* **modelOverride**: A set of overrides to apply to the model. Optional.
* **httpClientConfiguration**: Configuration for the generated http service clients. The schema for this parameOptional.
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
  - (base-name)Client
  - (base-name)Model
  - (base-name)Operations
  - (base-name)OperationsHTTP1
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

## License

This library is licensed under the Apache 2.0 License.
