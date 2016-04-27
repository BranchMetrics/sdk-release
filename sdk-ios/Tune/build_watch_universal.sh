TARGET_OS=watch
BUILD_TARGET_NAME=Tune_watchOS
UNIVERSAL_FRAMEWORK_NAME=Tune_watchOS

UNIVERSAL_OUTPUT_FOLDER=${BUILD_DIR}/${CONFIGURATION}-${TARGET_OS}-universal
PROJECT_BUILD_OUTPUT_FOLDER=${SRCROOT}/build/${TARGET_OS}/${CONFIGURATION}

if [ "true" == ${ALREADYINVOKED:-false} ]
then
echo "RECURSION: Detected, stopping"
else
export ALREADYINVOKED="true"

# Step 0. Ensure that the universal binary output folder exists.
mkdir -p "${UNIVERSAL_OUTPUT_FOLDER}"
mkdir -p "${SRCROOT}/build/${TARGET_OS}/${CONFIGURATION}"

# Step 1. Build Device and Simulator versions
xcodebuild -project "${PROJECT_FILE_PATH}" -target "${BUILD_TARGET_NAME}" -configuration ${CONFIGURATION} -sdk ${TARGET_OS}os        ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -project "${PROJECT_FILE_PATH}" -target "${BUILD_TARGET_NAME}" -configuration ${CONFIGURATION} -sdk ${TARGET_OS}simulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

echo "cp -R ${BUILD_DIR}/${CONFIGURATION}-${TARGET_OS}os/${UNIVERSAL_FRAMEWORK_NAME}.framework ${UNIVERSAL_OUTPUT_FOLDER}"

# Step 2. Copy the framework structure (from ${TARGET_OS}os build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-${TARGET_OS}os/${UNIVERSAL_FRAMEWORK_NAME}.framework" "${UNIVERSAL_OUTPUT_FOLDER}"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUT_FOLDER}/${UNIVERSAL_FRAMEWORK_NAME}.framework/${UNIVERSAL_FRAMEWORK_NAME}" "${BUILD_DIR}/${CONFIGURATION}-${TARGET_OS}simulator/${UNIVERSAL_FRAMEWORK_NAME}.framework/${UNIVERSAL_FRAMEWORK_NAME}" "${BUILD_DIR}/${CONFIGURATION}-${TARGET_OS}os/${UNIVERSAL_FRAMEWORK_NAME}.framework/${UNIVERSAL_FRAMEWORK_NAME}"

# Step 4. Clean/create the build directory and copy the project resources.
rm -rf "${SRCROOT}/build/${TARGET_OS}/${CONFIGURATION}"
rm -rf "${SRCROOT}/build/${PROJECT_NAME}.build"
mkdir "${SRCROOT}/build/${TARGET_OS}/${CONFIGURATION}"
cp -a "${UNIVERSAL_OUTPUT_FOLDER}/${UNIVERSAL_FRAMEWORK_NAME}.framework" "${PROJECT_BUILD_OUTPUT_FOLDER}/${UNIVERSAL_FRAMEWORK_NAME}.framework"

fi
