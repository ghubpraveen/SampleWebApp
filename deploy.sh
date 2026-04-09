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

echo "🔨 Starting Maven WAR build..."
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

DEPLOY_DIR= "/home/praveen/app_scripts"
cp "$WAR_FILE" "$DEPLOY_DIR/SampleWebAPP-${COMMIT_HASH:0:7}.war"

if [[-f "$DEPLOY_DIR/SampleWebApp-${COMMIT_HASH:0:7}.war"]]: then
    echo "✅ WAR copied successfully!"
else
    echo "❌ WAR copy failed"
    exit 1
fi
