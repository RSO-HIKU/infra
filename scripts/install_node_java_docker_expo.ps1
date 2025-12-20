<#
    Hiku-App Team Setup Script
    Installs all required tools for frontend and backend development:
    - Node.js + NPM
    - Java JDK 21 + Maven
    - Docker Desktop
    - VS Code extensions
    - Expo CLI
#>

# =========================
# 1️⃣ Node.js + NPM
# =========================
Write-Host "`nInstalling/upgrading Node.js LTS (v24.11.0)..." -ForegroundColor Cyan
winget upgrade OpenJS.NodeJS.LTS --version 24.11.0 --accept-package-agreements --accept-source-agreements

# =========================
# 2️⃣ Java JDK 21 + Maven
# =========================
Write-Host "`nInstalling Java JDK 21..." -ForegroundColor Cyan
winget install EclipseAdoptium.Temurin.21.JDK --accept-package-agreements --accept-source-agreements

# MAVEN ROČNO PRENEŠ ZIP apache-maven-3.9.11-bin.zip iz https://maven.apache.org/download.cgi
# EKSTRAHIRAŠ V C:\Program Files 
# NE POZABI DODATI V PATH in USTVARITI NOVE MAVEN_HOME systems variable

# =========================
# 3️⃣ Docker Desktop
# =========================
Write-Host "`nInstalling Docker Desktop..." -ForegroundColor Cyan
winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements

# =========================
# 4️⃣ VS Code Extensions
# =========================
Write-Host "`nInstalling VS Code extensions..." -ForegroundColor Cyan

# Java & Spring
code --install-extension vscjava.vscode-java-pack
code --install-extension vscjava.vscode-spring-boot-dashboard

# Docker & Kubernetes
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# YAML support
code --install-extension redhat.vscode-yaml

# Code formatting & React snippets
code --install-extension esbenp.prettier-vscode
code --install-extension dsznajder.es7-react-js-snippets

# =========================
# 5️⃣ Expo CLI
# =========================
Write-Host "`nInstalling Expo CLI globally..." -ForegroundColor Cyan
npm install -g expo-cli

# =========================
# 6️⃣ Verify installations
# =========================
Write-Host "`nVerifying installations..." -ForegroundColor Green
Write-Host "Node.js:" -NoNewline
node -v

Write-Host "NPM:" -NoNewline
npm -v

Write-Host "Java:" -NoNewline
java -version

Write-Host "Docker:" -NoNewline
docker --version

Write-Host "Expo CLI:" -NoNewline
expo --version

Write-Host "`n✅ All tools installed successfully!" -ForegroundColor Green
