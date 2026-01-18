#!/bin/bash

echo "🧹 Corrigindo sintaxe YAML e alinhamento do Gradle..."

# 1. Adicionar ao gitignore
if ! grep -q "fix_syntax.sh" .gitignore; then
    echo "fix_syntax.sh" >> .gitignore
fi

# 2. Criar o arquivo build.gradle da raiz (Separado para evitar erro de cat)
cat <<EOF > build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.2.0' }
}
allprojects {
    repositories { google(); mavenCentral() }
}
EOF

# 3. Criar o build.gradle do App (Separado e limpo)
mkdir -p app
cat <<EOF > app/build.gradle
plugins { id 'com.android.application' }
android {
    namespace 'com.salyan.biblia'
    compileSdk 34
    defaultConfig {
        applicationId "com.salyan.biblia"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
        }
    }
    splits {
        abi {
            enable true
            include "armeabi-v7a", "arm64-v8a"
            universalApk true
        }
    }
}
EOF

# 4. Criar o Robô (Workflow) SUPER SIMPLIFICADO para evitar erro de sintaxe
mkdir -p .github/workflows
cat <<EOF > .github/workflows/android.yml
name: Build Nativo
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Generate Icons
        run: |
          npm install -g @capacitor/assets
          mkdir -p assets
          [ -f "icon.png" ] && cp icon.png assets/icon.png
          npx @capacitor/assets generate --android --assetPath assets --androidProject app || echo "Icons failed"

      - name: Build APK
        run: |
          gradle wrapper --gradle-version 8.4
          chmod +x gradlew
          ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: Biblia-Final-APK
          path: app/build/outputs/apk/debug/*.apk
EOF

# 5. Enviar
echo "📤 Enviando arquivos corrigidos..."
git add .github/workflows/android.yml build.gradle app/build.gradle .gitignore
git commit -m "Fix: Corrigindo sintaxe do Workflow e arquivos Gradle"
git push origin main

echo "✅ Script finalizado! Verifique o Actions agora."