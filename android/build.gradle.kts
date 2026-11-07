// Mantén este archivo mínimo para evitar conflictos de versiones.
// No declares aquí plugins ni repositorios: todo va en settings.gradle.kts.

// Deja la compilación en la carpeta build/ del proyecto, que es donde Flutter busca el .apk
val carpetaBuild: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(carpetaBuild)

subprojects {
    project.layout.buildDirectory.value(carpetaBuild.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
