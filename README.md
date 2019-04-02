<p align="center">
<a href="https://travis-ci.com/amzn/smoke-framework-application-generate">
<img src="https://travis-ci.com/amzn/smoke-framework-application-generate.svg?branch=master" alt="Build - Master Branch">
</a>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-4.1-orange.svg?style=flat" alt="Swift 4.1 Compatible">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-4.2-orange.svg?style=flat" alt="Swift 4.2 Compatible">
</a>
<a href="https://gitter.im/SmokeServerSide">
<img src="https://img.shields.io/badge/chat-on%20gitter-ee115e.svg?style=flat" alt="Join the Smoke Server Side community on gitter">
</a>
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>

# SwiftAWSGenerate

Code generator to generate [SmokeFramework](https://github.com/amzn/smoke-framework)-based applications from service models.

# Generate a SmokeFramework application package from a Swagger 2.0 specification file

## Step 1: Check out this repository

Clone this repository to your local machine.

## Step 3: Run the code generator

From within your checked out copy of this repository, run this command-

```bash
swift run -c release SmokeFrameworkApplicationGenerate \
  --base-file-path <output_file_path> \
  --base-name <base_client_name> \
  --model-path <file_path_to_model> \
  --generation-type [server: to generate a new service|serverUpdate: to preserve changes to existing operation handlers]
 [--model-override-path <file_path_to_model_override>]
```

## License

This library is licensed under the Apache 2.0 License.
