buildscript {
    repositories {
        google()  // Repositório do Google para o plugin google-services
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.0.4")  // Certifique-se de que esta versão esteja correta
        classpath("com.google.gms:google-services:4.4.2")  // Plugin Google Services
    }
}

allprojects {
    repositories {
        google()  // Necessário para o plugin Google Services
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
