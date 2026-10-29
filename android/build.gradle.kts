allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            androidExt?.compileSdkVersion(35)
        }
    }
}
subprojects {
    configurations.configureEach {
        exclude(group = "com.android.support")
    }
    plugins.withId("com.android.library") {
        val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null && androidExt.namespace == null) {
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            var manifestPkg: String? = null
            if (manifestFile.exists()) {
                val match = Regex("""package="([^"]+)"""").find(manifestFile.readText())
                if (match != null) {
                    manifestPkg = match.groupValues[1]
                }
            }
            androidExt.namespace = manifestPkg ?: "com.example.${project.name.replace('-', '_')}"
        }
    }
    plugins.withId("com.android.application") {
        val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null && androidExt.namespace == null) {
            androidExt.namespace = "com.example.${project.name.replace('-', '_')}"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
