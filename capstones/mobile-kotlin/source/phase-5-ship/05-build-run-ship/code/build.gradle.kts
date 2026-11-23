plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
}
val generator = configurations.create("generator")
dependencies { generator("org.openapitools:openapi-generator-cli:7.27.0") }
tasks.register<JavaExec>("openApiGenerate") {
    group = "code generation"
    classpath = generator
    mainClass.set("org.openapitools.codegen.OpenAPIGenerator")
    args("generate", "-i", "$rootDir/contract/openapi.yaml", "-g", "kotlin",
        "-c", "$rootDir/openapi/generator-config.json",
        "-o", "$rootDir/app/src/main/kotlin-generated",
        "--global-property", "apis,models,supportingFiles=CollectionFormats.kt,apiDocs=false,modelDocs=false,apiTests=false,modelTests=false",
        "--ignore-file-override", "$rootDir/openapi/.openapi-generator-ignore")
}
