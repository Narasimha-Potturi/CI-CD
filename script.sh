#!/bin/bash
set -e

REPO_NAME="desktopapp-magik-repo"

echo "Creating repo folder: $REPO_NAME"
mkdir -p "$REPO_NAME"
cd "$REPO_NAME"

echo "Creating folder structure..."
mkdir -p src/modules/login
mkdir -p src/modules/billing
mkdir -p src/modules/common
mkdir -p src/config
mkdir -p src/ui
mkdir -p scripts

echo "Creating files with sample content..."

# README
cat > README.md <<'EOF'
# DesktopApp Magik Repo (Sample)

This is a sample repository structure for testing Jenkins deployments of changed files only.
EOF

# Magik sample files
cat > src/modules/login/login.magik <<'EOF'
# login.magik (sample)
_method login(user, pass)
  _print("Login called for user: " + user)
  _return true
_endmethod
EOF

cat > src/modules/login/login_helper.magik <<'EOF'
# login_helper.magik (sample)
_method validate_user(user)
  _print("Validating user: " + user)
  _return true
_endmethod
EOF

cat > src/modules/billing/invoice.magik <<'EOF'
# invoice.magik (sample)
_method generate_invoice(order_id)
  _print("Generating invoice for order: " + order_id)
  _return "INV-" + order_id.as_string()
_endmethod
EOF

cat > src/modules/billing/tax_calc.magik <<'EOF'
# tax_calc.magik (sample)
_method calculate_tax(amount)
  _print("Calculating tax for amount: " + amount.as_string())
  _return amount * 0.18
_endmethod
EOF

cat > src/modules/common/utils.magik <<'EOF'
# utils.magik (sample)
_method log_message(msg)
  _print("LOG: " + msg)
_endmethod
EOF

cat > src/modules/common/constants.magik <<'EOF'
# constants.magik (sample)
_constant APP_NAME << "DesktopApp"
_constant APP_VERSION << "1.0.0"
EOF

# UI files
cat > src/ui/main_screen.magik <<'EOF'
# main_screen.magik (sample)
_method load_main_screen()
  _print("Loading Main Screen...")
_endmethod
EOF

cat > src/ui/theme.magik <<'EOF'
# theme.magik (sample)
_method apply_theme()
  _print("Applying default theme...")
_endmethod
EOF

# Config files
cat > src/config/app.properties <<'EOF'
app.name=DesktopApp
app.version=1.0.0
app.mode=development
EOF

cat > src/config/env.properties <<'EOF'
env=DEV
logging.level=INFO
EOF

# Scripts
cat > scripts/pre_deploy.ps1 <<'EOF'
Write-Host "Pre-deploy script running..."
EOF

cat > scripts/post_deploy.ps1 <<'EOF'
Write-Host "Post-deploy script running..."
EOF

# Jenkinsfile (Changed files deployment pipeline)
cat > Jenkinsfile <<'EOF'
pipeline {
    agent any

    parameters {
        string(
            name: 'TARGET_ROOT',
            defaultValue: 'C:\\DesktopApp',
            description: 'Target base folder where files should be deployed'
        )
    }

    environment {
        CHANGE_FILE = "changed_files.txt"
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Detect Changed Files') {
            steps {
                script {
                    bat """
                    git diff --name-only HEAD~1 HEAD > ${CHANGE_FILE}
                    """

                    def changes = readFile("${CHANGE_FILE}").trim()
                    if (!changes) {
                        error "No changed files detected. Nothing to deploy."
                    }

                    echo "Changed files detected:\\n${changes}"
                }
            }
        }

        stage('Verify Changed Files') {
            steps {
                script {
                    def changes = readFile("${CHANGE_FILE}").trim().split("\\r?\\n")

                    echo "Verifying changed files exist in workspace..."

                    changes.each { f ->
                        if (!fileExists(f)) {
                            error "Changed file missing in workspace: ${f}"
                        }
                    }

                    echo "All changed files exist in workspace."
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Approve deployment of changed files to ${params.TARGET_ROOT}?"
            }
        }

        stage('Deploy Changed Files') {
            steps {
                bat """
                for /f "usebackq delims=" %%f in ("${CHANGE_FILE}") do (
                    echo Deploying %%f

                    powershell -Command ^
                    "$src='%%f'; ^
                     $dest='${params.TARGET_ROOT}\\\\' + $src; ^
                     $destDir=Split-Path $dest -Parent; ^
                     if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }; ^
                     Copy-Item -Path $src -Destination $dest -Force"
                )
                """
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully to ${params.TARGET_ROOT}"
        }
        failure {
            echo "Deployment failed."
        }
    }
}
EOF

echo "Initializing git repository..."
git init
git add .
git commit -m "Initial sample Magik repo structure for Jenkins deployment testing"

echo ""
echo "Done!"
echo "Repo created at: $(pwd)"
echo ""
echo "Next steps:"
echo "1) Create a GitHub repo (public)"
echo "2) Push this repo:"
echo "   git branch -M main"
echo "   git remote add origin https://github.com/<user>/<repo>.git"
echo "   git push -u origin main"

