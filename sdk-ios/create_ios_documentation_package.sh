# To run script, run this script within the sdk-ios folder:
# ./create_ios_documentation_package.sh <SDK version number i.e. 5.1.0>

#!/bin/bash

PUBLIC_REPO_NAME="TuneOSS"
SDK_VERSION_NUMBER=$1
LATEST_GIT_TAG=${SDK_VERSION_NUMBER}
# May be able to use these variables instead once we've incorporated this script into Mario's iOS automation process:
# LATEST_GIT_TAG=$(git describe --abbrev=0 --tags)
# SDK_VERSION_NUMBER=${LATEST_GIT_TAG}
DOCSET_NAMESPACE="com.tune.Tune"

#  Creates the JazzyDocs html for the version number (see https://github.com/realm/jazzy for framework documentation)
create_jazzy_docs() {
# --skip-documentation can be added to only generates a json inventory of what areas of the docs are missing header comments (i.e. no html/zip files)
# (NOTE: make sure to add a backslash after --module-version ${LATEST_GIT_TAG} if you uncomment --skip-documentation)
jazzy \
--objc \
--clean \
--output ../docs/JazzyDocs/${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html \
--sdk iphonesimulator \
--umbrella-header ./Tune/Tune/Tune.h \
--hide-declarations swift \
--undocumented-text "" \
--author Tune, Inc. \
--author_url https://developers.tune.com/ \
--github_url https://github.com/${PUBLIC_REPO_NAME}/sdk-release/tree/${LATEST_GIT_TAG}/sdk-ios \
--github-file-prefix https://github.com/${PUBLIC_REPO_NAME}/sdk-release/blob/${LATEST_GIT_TAG}/sdk-ios \
--module Tune \
--module-version ${LATEST_GIT_TAG}
# --skip-documentation
}

create_jazzy_docs

# <local file path>/ios-sdk/sdk-ios
cd ..
# <local file path>/ios-sdk
cd docs/JazzyDocs/${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html

# Creates the tar package from the JazzyDocs files and moves the zip file to the correct location
# (if build is not flagged with --skip-documentation)
html_file_count=`ls -1 *.html 2>/dev/null | wc -l | sed -e 's/^[[:space:]]*//'`
if [ $html_file_count != 0 ] ; then
  cd ..
  tar -zcvf ${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html.tar.gz ${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html
  mv ${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html.tar.gz ../${DOCSET_NAMESPACE}-${SDK_VERSION_NUMBER}.html.tar.gz
fi


# TODO: Issues for Jennifer and Mario to address when incorporating into the automated build script

# 1. Need to account for incorrect git tags we wouldn't want to generate with
# and have a backup (i.e. possibly a version number entered as an argument to use,
# even in the fully incorporated script?)

# 2. When the full documentation is run for a version, running with --skip-documentation
# does not just overwrite the json file. It overwrites the folder containing the documentation files.
# (Causing the html, css, etc. files to be effectively sdeleted.)
# This is low risk for now because we would still have the archive file preserved in a separate folder, but
# we should consider saving the --skip-documentation generated inventory json in a separate folder to avoid this behavior.
