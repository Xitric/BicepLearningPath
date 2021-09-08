# Migrate ARM templates to Bicep
Microsoft recommends the following workflow for migrating an existing infrastructure from manual portal creation and ARM templates to using Bicep:

![Bicep migration process](https://docs.microsoft.com/en-us/learn/modules/migrate-azure-resources-bicep/media/8-migrate-bicep-numbers.png)

## Convert
For manually created resources, we use the Azure portal to export an ARM template of our infrastructure.
A consequence of this approach is that parameters will end up being hard-coded, there might be unnecessary default values in the ARM template, and some resources can end up missing altogether.

For resources originally created using ARM, we likely already have this template.
Then, we use command line tools to decompile the ARM template into Bicep.
This resulting Bicep file is not production-ready, and should be used purely for inspiration.

## Migrate
This step is only relevant if exporting an existing infrastructure to ARM templates before decompiling to Bicep.
It is a three-step process:

1. Create a new, empty Bicep file: This becomes the basis for the final, production-grade template.
2. Copy each resource from the decompiled template: For each resource, fix any apparent issues.
3. Recreate missing resources: During the ARM export, some errors may arise that we need to fix.

## Refactor
Update the code to follow Bicep best practices.
An example workflow is:

1. Review resource API versions.
    - Use newer versions if we need access to newly added properties on a resource.
2. Review linter suggestions.
3. Revise parameters, variables, and symbolic names.
4. Simplify expressions.
    - Especially remove `concat()` and `format()` functions, and use string interpolation instead.
5. Review child and extensions resources.
    - Child and extension resources should not be created by using string interpolation for name construction.
    - We should also determine if we want subnets to be added as properties on a virtual network, or as separate resources.
6. Modularize.
7. Add comments.

## Test
We should do a what-if operation on our resulting Bicep template against an existing infrastructure to verify that any changes introduced are acceptable.
Even if we plan to do incremental deployments, we should run what-if in complete mode to detect any resources we may have missed in the migration.

We should also consider running multiple test deployments alongside the existing infrastructure.
We can then compare resources one by one for validity.

## Deploy

