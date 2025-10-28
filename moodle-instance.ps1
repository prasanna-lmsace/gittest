# Set variables
$moodleVersion = "MOODLE_405_STABLE" # Specify the Moodle version/branch to clone
$moodleRepo = "https://github.com/moodle/moodle.git"
$installDir = "D:\xampp\htdocs\mthemes\moodle-45" # Change to your desired Moodle installation directory
$dataDir = "D:\xampp\moodledata\moodle-45" # Change to your desired Moodle data directory
$dbName = "moodle-45" # Change to your desired database name
$dbUser = "root" # Change to your XAMPP MySQL user
$dbPass = "" # Change to your XAMPP MySQL password
# Function to confirm user action
function Confirm-Action {
    param (
        [string]$Message
    )
    Write-Host $Message
    $confirmation = Read-Host "Type 'yes' to proceed, or any other key to cancel"
    if ($confirmation -ne "yes") {
        Write-Host "Operation canceled by user."
        exit
    }
}

# Step 0: Cleanup existing installation
Write-Host "Cleaning up existing Moodle installation..."
Confirm-Action "This will delete the existing Moodle directory, data directory, and database ($dbName). Are you sure?"

# Cleanup Moodle directory
if (Test-Path -Path $installDir) {
    Write-Host "Deleting Moodle installation directory..."
    Remove-Item -Recurse -Force -Path $installDir
} else {
    Write-Host "Moodle installation directory does not exist. Skipping."
}

# Cleanup data directory
if (Test-Path -Path $dataDir) {
    Write-Host "Deleting Moodle data directory..."
    Remove-Item -Recurse -Force -Path $dataDir
} else {
    Write-Host "Moodle data directory does not exist. Skipping."
}

# Cleanup database
Write-Host "Deleting database..."
$mysqlDropCommand = @"
DROP DATABASE IF EXISTS $dbName;
"@
$mysqlPath = "D:\xampp\mysql\bin\mysql.exe" # Path to MySQL executable
& $mysqlPath -u$dbUser -p$dbPass -e $mysqlDropCommand

# Step 1: Clone the Moodle repository
Write-Host "Cloning Moodle repository..."
if (-Not (Test-Path -Path $installDir)) {
    git clone $moodleRepo $installDir
} else {
    Write-Host "Moodle directory already exists. Skipping cloning step."
}

# Step 2: Checkout to the specified branch
Write-Host "Checking out to branch: $moodleVersion..."
Set-Location -Path $installDir
git fetch --all
git checkout $moodleVersion

# Step 3: Create data directory
Write-Host "Creating data directory..."
if (-Not (Test-Path -Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir
} else {
    Write-Host "Data directory already exists. Skipping this step."
}

# Step 4: Create database
Write-Host "Creating database..."
$mysqlCreateCommand = @"
CREATE DATABASE IF NOT EXISTS $dbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
"@
& $mysqlPath -u$dbUser -p$dbPass -e $mysqlCreateCommand

# Step 5: Initialize Moodle installation
Write-Host "Initializing Moodle installation..."
$phpPath = "D:\xampp\php83\php.exe" # Path to PHP executable
$installCli = Join-Path -Path $installDir -ChildPath "admin\cli\install.php"

& $phpPath $installCli `
    --non-interactive `
    --agree-license `
    --wwwroot="http://localhost:8383/mthemes/moodle-45" `
    --dataroot=$dataDir `
    --dbtype="mariadb" `
    --dbname=$dbName `
    --dbuser=$dbUser `
    --dbpass=$dbPass `
    --fullname="Moodle 45 Test Site" `
    --shortname="moodle-45" `
    --adminuser="admin" `
    --adminpass="Admin123#" # Replace with a secure password!

Write-Host "Moodle instance created successfully! Access it at http://localhost:8383/mthemes/moodle-45"
