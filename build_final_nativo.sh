#!/bin/bash

echo "🛠️ Preparando os arquivos de construção nativa..."

# 1. Adicionar ao gitignore
if ! grep -q "build_final_nativo.sh" .gitignore; then
    echo "build_final_nativo.sh" >> .gitignore
fi

# 2. Criar o arquivo de configuração de propriedades do Gradle
cat <<EOF > gradle.properties
android.useAndroidX=true
android.enableJetifier=true
EOF

# 3. Criar o arquivo de configurações do projeto
cat <<EOF > settings.gradle
include ':app'
rootProject.name = "Biblia Pro"
EOF

# 4. Criar o Robô "Inteligente" (Workflow)
# Ele vai baixar o Gradle sozinho no servidor do GitHub
mkdir -p .github/workflows
cat <<EOF > .github/workflows/android.yml
name: Build Nativo Completo
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

      - name: Generate App Icons
        run: |
          npm install -g @capacitor/assets
          mkdir -p assets
          cp icon.png assets/icon.png || echo "Sem icone"
          # Gera os icones direto na pasta de recursos
          npx @capacitor/assets generate --android --assetPath assets --androidProject app || echo "Pulo icones"

      - name: Setup Android Project Files
        run: |
          # Cria o build.gradle da raiz
          cat <<EOT > build.gradle
          buildscript {
              repositories { google(); mavenCentral() }
              dependencies { classpath 'com.android.tools.build:gradle:8.2.0' }
          }
          allprojects {
              repositories { google(); mavenCentral() }
          }
EOT
          # Cria o build.gradle do App (Aqui configuramos ARMv7)
          cat <<EOT > app/build.gradle
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
                  testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
              }
              buildTypes {
                  release {
                      minifyEnabled false
                  }
              }
              // Garante suporte a 32 bits e 64 bits
              splits {
                  abi {
                      enable true
                      include "armeabi-v7a", "arm64-v8a"
                      universalApk true
                  }
              }
          }
EOT

      - name: Build with Gradle
        run: |
          # Comando mágico que instala o Gradle no servidor
          gradle wrapper --gradle-version 8.4
          chmod +x gradlew
          ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: BibliaPro-Nativa-ARMv7
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

# 5. Enviar para o GitHub
echo "📤 Subindo correção dos arquivos de build..."
git add .
git commit -m "Fix: Adicionado Gradle Wrapper e arquivos de projeto nativo"
git push origin main

echo "🚀 TUDO PRONTO! Agora o robô tem a chave e o motor para compilar."