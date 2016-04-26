TUNE Android SDK
====================

#Build

- Install [Android Studio](http://developer.android.com/tools/studio/index.html)

- `gradle makeJar` creates `/dist/MobileAppTracker-x.y.z.jar`

- `gradle clean assemble` creates `/MobileAppTracker/build/outputs/aar/MobileAppTracker-release.aar` and `/MobileAppTracker/build/libs/MobileAppTracker-javadoc.jar`

#Test

- `gradle connectedCheck --info` runs instrumentation tests in `/MobileAppTracker/src/androidTest`