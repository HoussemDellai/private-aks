# Install chocolately
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Terminal
choco install microsoft-windows-terminal -y

# Install Azure CLI
choco install azure-cli -y
# Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

# Install Kubernetes CLI
choco install kubernetes-cli -y

# Install Helm CLI
choco install kubernetes-helm -y

# Install Terraform
choco install terraform -y

# Install jq
choco install jq -y

# Install VS Code
choco install vscode -y
# Set-ExecutionPolicy Bypass -Scope Process -Force; Install-Script Install-VSCode -Scope CurrentUser; Install-VSCode.ps1 

# Install Edge
choco install microsoft-edge -y

# Install Git
choco install git -y

# Install Azure Storage Explorer
choco install microsoftazurestorageexplorer -y

# Install curl
choco install curl -y

# Start new PS window with VS Code and Git configured
# Restart-Service -Name "powershell.exe"
# invoke-expression 'cmd /c start powershell -Command { 
# Install Terraform extension in VS Code
code --install-extension hashicorp.terraform

cd "C:\Users\houssem\Desktop"
git clone https://github.com/HoussemDellai/private-aks
cd private-aks
Code .

az login
az account set --subscription "Microsoft Azure #5"
az aks list -o table
az aks get-credentials -g demo0051-aks-rg -n demo0051-aks

cd stage2
terraform init
terraform plan -out tfplan