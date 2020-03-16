<p align="center">
<a href="https://travis-ci.com/amzn/smoke-framework-application-generate">
<img src="https://travis-ci.com/amzn/smoke-framework-application-generate.svg?branch=smoke-framework-application-generate-1.x" alt="Build - smoke-framework-application-generate-1.x Branch">
</a>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-4.2-orange.svg?style=flat" alt="Swift 4.2 Compatible">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.0-orange.svg?style=flat" alt="Swift 5.0 Compatible">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.1-orange.svg?style=flat" alt="Swift 5.1 Compatible">
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

## Step 4: Run the code generator

From within your checked out copy of this repository, run this command-

```bash
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path <the path to where you want the service to be generated> \
  --base-name <a base name for your service (without the "Service" postfix)> \
  --model-path <the path to the Swagger model you created> \
  --generation-type [server: to generate a new service|serverUpdate: to preserve changes to existing operation handlers]
 [--model-override-path <optionally the path to a json file that specifies various overrides to the model>]
```

And example command would look like this-

```bash
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService \
  --base-name PersistenceExample \
  --model-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService/Swagger.yaml \
  --generation-type server \
  --model-override-path /Volumes/Workspace/smoke-framework-examples/PersistenceExampleService/modelOverride.json
```

An example service based on the command above can be found [here](https://github.com/amzn/smoke-framework-examples/tree/master/PersistenceExampleService).

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
A `generation-type` of `serverUpdate` will not overwrite changes in these sections-

* **(base-name)Operations:** Stub implementations for each operation; should be modified to fullfill the services's logic.
* **(base-name)OperationsTests:** Stub test implementations for each operation; should be modified to test the services's logic.
* **(base-name)Service:** Operations context initialization and shutdown code; should be modified to create the context for the current environment.

The following three section contain code generated code to help the service operate but should not be manually modified. 
A `generation-type` of `serverUpdate` will overwrite changes in these sections-

* **(base-name)Client:** APIGateway and mock clients for the service; should not be manually modified.
* **(base-name)Client:** Input and output structures and types for the service; should not be manually modified.
* **(base-name)Client:** Operation selection and input/output type handling specific to HTTP1; should not be manually modified.

## License

This library is licensed under the Apache 2.0 License.
