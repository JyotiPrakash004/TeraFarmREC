allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
<<<<<<< HEAD
plugins {
  // ...
  
  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.2" apply false
  id("com.android.application") version "8.7.0" apply false
  id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}
=======

>>>>>>> 1ade028f5ff23de3dde1390dc19f70ec431e725e
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
