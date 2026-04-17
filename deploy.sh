#!/bin/bash
# java_deployment.sh
# Reads params from file and builds the WAR

set -e
trap 'echo "❌ Failed at line $LINENO"' ERR

# ── Step 1: Read the params file ──────────────────────────
PARAMS_FILE=$1

if [[ -z "$PARAMS_FILE" || ! -f "$PARAMS_FILE" ]]; then
    echo "❌ ERROR: Params file not found: $PARAMS_FILE"
    exit 1
fi

echo "📄 Reading params from: $PARAMS_FILE"
set -a                   # auto-export all variables
source "$PARAMS_FILE"
set +a

# ── Step 2: Print what we got ─────────────────────────────
echo "==============================="
echo "JOB_NAME    : $JOB_NAME"
echo "BRANCH      : $BRANCH"
echo "COMMIT_HASH : $COMMIT_HASH"
echo "BUILD_ENV   : $BUILD_ENV"
echo "REQUIRED    : $REQUIRED"
echo "WORKSPACE   : $WORKSPACE"
echo "==============================="

# ── Step 3: Go to workspace and build WAR ─────────────────
cd "$WORKSPACE"

echo "🔨 Starting Maven WAR build...."
mvn clean package -DskipTests

# ── Step 4: Confirm WAR was created ───────────────────────
WAR_FILE="$WORKSPACE/target/SampleWebApp.war"

if [[ -f "$WAR_FILE" ]]; then
    echo "✅ WAR built successfully: $WAR_FILE"
    ls -lh "$WAR_FILE"
else
    echo "❌ WAR file not found after build!"
    exit 1
fi

DEPLOY_DIR="$WORKSPACE/app_scripts/"
cp "$WAR_FILE" "$DEPLOY_DIR/SampleWebAPP-${COMMIT_HASH:0:7}.war"

if [[ -f "$DEPLOY_DIR/SampleWebAPP-${COMMIT_HASH:0:7}.war" ]]; then
    echo "✅ WAR copied successfully!"
else
    echo "❌ WAR copy failed"
    exit 1
fi

# # ── Step 6: Deploy to Tomcat ──────────────────────────────
# TOMCAT_WEBAPPS="/var/lib/tomcat9/webapps"
# APP_NAME="SampleWebApp"

# echo "🚀 Starting Tomcat deployment..."

# # Stop Tomcat
# echo "⏹ Stopping Tomcat..."
# sudo systemctl stop tomcat9

# # Remove old deployment
# if [[ -d "$TOMCAT_WEBAPPS/$APP_NAME" ]]; then
#     echo "🗑 Removing old deployment..."
#     sudo rm -rf "$TOMCAT_WEBAPPS/$APP_NAME"
# fi

# if [[ -f "$TOMCAT_WEBAPPS/$APP_NAME.war" ]]; then
#     echo "🗑 Removing old WAR..."
#     sudo rm -f "$TOMCAT_WEBAPPS/$APP_NAME.war"
# fi

# # Copy new WAR to Tomcat
# echo "📂 Copying new WAR to Tomcat..."
# sudo cp "$WAR_FILE" "$TOMCAT_WEBAPPS/$APP_NAME.war"

# # Start Tomcat
# echo "▶ Starting Tomcat..."
# sudo systemctl start tomcat9

# # ── Step 7: Verify Deployment ─────────────────────────────
# echo "⏳ Waiting for Tomcat to deploy WAR..."
# sleep 15

# if [[ -d "$TOMCAT_WEBAPPS/$APP_NAME" ]]; then
#     echo "✅ Deployment successful!"
#     echo "🌐 App available at: http://localhost:8080/$APP_NAME"
# else
#     echo "❌ Deployment failed — folder not created by Tomcat"
#     exit 1
# fi