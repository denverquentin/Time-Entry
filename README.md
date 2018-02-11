# Time Entry Application
Metadata, Apex Code and build/migration script for a Time Entry application build on the Salesforce Platform.

[Apex Classes Documentation](/apexDocumentation/SfApexDocs/index.html)
------
##### Salesforce Objects Used and Why
The data model in Salesforce is based on [Version 2 of the Harvest API](https://help.getharvest.com/api-v2/).

------
##### Ant Build Script
The build.xml Ant Script contains the following targets:
* `help` - shows all available targets in the build script
* `getMetadata` - gets all metadata from SF - stores in `src` dir
* `saveLightning` - saves all lightning components from local to SF
* `runTests` - runs all tests in SF
* `deployMetadata` - deploy all local metadata to SF
* `checkMetadataDeploy` - does a check on a local metadata deploy to SF
* `generateDocumentation` - generates documentation for apex classes

