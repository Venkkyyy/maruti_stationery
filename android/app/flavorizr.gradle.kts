import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("customer") {
            dimension = "flavor-type"
            applicationId = "com.example.maruti_stationery"
            resValue(type = "string", name = "app_name", value = "Maruti Stationery")
        }
        create("admin") {
            dimension = "flavor-type"
            applicationId = "com.example.maruti_stationery"
            resValue(type = "string", name = "app_name", value = "Maruti Admin")
        }
    }

    buildFeatures.resValues = true
}