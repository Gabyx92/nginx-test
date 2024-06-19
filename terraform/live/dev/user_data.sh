#!/bin/bash
# Update the package index
sudo apt-get update -y

# Install Apache (httpd equivalent on Ubuntu)
sudo apt-get install -y apache2

# Start Apache service
sudo systemctl start apache2

# Enable Apache to start on boot
sudo systemctl enable apache2

# Get the instance ID
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=$(curl curl http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN")

# Create a simple HTML page
echo "<html>
<head>
    <title>Web Server</title>
</head>
<body>
    <h1>Hello human! I'm running from instance $INSTANCE_ID</h1>
</body>
</html>" | sudo tee /var/www/html/index.html
