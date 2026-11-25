import java.io.FileInputStream
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

val versionProps = Properties().apply {
    val file = File(rootDir, "version.properties")
    if (file.exists()) load(FileInputStream(file))
}
val vCode = versionProps.getProperty("VERSION_CODE", "1").toInt()
val vName = versionProps.getProperty("VERSION_NAME", "1.0.0")

// Release signing: android/keystore.properties (gitignored): storeFile, storePassword, keyAlias, keyPassword.
val keystoreProps = Properties().apply {
    val file = File(rootDir, "keystore.properties")
    if (file.exists()) load(FileInputStream(file))
}
val hasReleaseKeystore = keystoreProps.getProperty("storeFile") != null

// local.properties (gitignored): GOOGLE_WEB_CLIENT_ID (empty hides Google sign-in), MYNINE_BASE_URL (debug only).
val localProps = Properties().apply {
    val file = File(rootDir, "local.properties")
    if (file.exists()) load(FileInputStream(file))
}
fun prop(name: String, default: String = ""): String =
    (project.findProperty(name) as String?) ?: localProps.getProperty(name) ?: default

android {
    namespace = "uz.mynine.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "uz.mynine.app"
        minSdk = 26
        targetSdk = 36
        versionCode = vCode
        versionName = vName
        buildConfigField("String", "GOOGLE_WEB_CLIENT_ID", "\"${prop("GOOGLE_WEB_CLIENT_ID")}\"")
        buildConfigField("String", "BASE_URL", "\"https://mynine.uz\"")
        vectorDrawables { useSupportLibrary = true }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release") else null
        }
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
            buildConfigField("String", "BASE_URL", "\"${prop("MYNINE_BASE_URL", "https://mynine.uz")}\"")
        }
    }

    // The exam room page (HTML/CSS/JS) is shared with the iOS app: shared/exam-room → assets/exam-room.
    sourceSets["main"].assets.srcDirs("src/main/assets", "../../shared")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures {
        compose = true
        buildConfig = true
    }

    applicationVariants.all {
        val variant = this
        outputs.map { it as com.android.build.gradle.internal.api.ApkVariantOutputImpl }
            .forEach { output -> output.outputFileName = "Mynine_v${variant.versionName}_${variant.buildType.name}.apk" }

        assembleProvider.configure {
            doLast {
                // Release APKs go to mynine.uz/releases (only the newest kept); debug builds stay in build/outputs.
                if (variant.buildType.name == "release") variant.outputs.forEach { output ->
                    val file = output.outputFile
                    if (file != null && file.exists()) {
                        val releasesDir = File(rootDir.parentFile, "releases").apply { mkdirs() }
                        releasesDir.listFiles { f -> f.name.startsWith("Mynine_v") && f.name.endsWith(".apk") }?.forEach { it.delete() }
                        val target = File(releasesDir, file.name)
                        file.copyTo(target, overwrite = true)
                        println("APK: ${target.absolutePath}")
                    }
                }
            }
        }
    }

    tasks.matching { it.name == "bundleRelease" }.configureEach {
        doLast {
            val bundleFile = File(layout.buildDirectory.asFile.get(), "outputs/bundle/release/app-release.aab")
            if (bundleFile.exists()) {
                val releasesDir = File(rootDir.parentFile, "releases").apply { mkdirs() }
                releasesDir.listFiles { f -> f.name.startsWith("Mynine_v") && f.name.endsWith(".aab") }?.forEach { it.delete() }
                val target = File(releasesDir, "Mynine_v${vName}_release.aab")
                bundleFile.copyTo(target, overwrite = true)
                println("AAB: ${target.absolutePath}")
            }
        }
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.appcompat)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.navigation.compose)
    debugImplementation(libs.androidx.ui.tooling)

    implementation(libs.androidx.credentials)
    implementation(libs.androidx.browser)
    implementation(libs.androidx.credentials.play.services.auth)
    implementation(libs.google.id)

    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.kotlinx.serialization)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)

    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.media3.exoplayer)
    implementation(libs.androidx.media3.datasource.okhttp)
    implementation(libs.coil.compose)

    testImplementation(libs.junit)
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any {
        it.name.contains("Release") && (it.name.startsWith("assemble") || it.name.startsWith("bundle") || it.name.startsWith("package"))
    }
    if (releaseRequested && !hasReleaseKeystore) {
        throw GradleException("Release signing is not configured: create android/keystore.properties.")
    }
}
