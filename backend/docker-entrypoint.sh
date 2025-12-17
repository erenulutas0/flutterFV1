#!/bin/bash
set -e

# Create symlink for espeak-ng-data if it doesn't exist
if [ -d "/piper/espeak-ng-data" ] && [ ! -d "/usr/share/espeak-ng-data" ]; then
    mkdir -p /usr/share
    ln -sf /piper/espeak-ng-data /usr/share/espeak-ng-data
    echo "Created symlink: /usr/share/espeak-ng-data -> /piper/espeak-ng-data"
fi

# Run the original Java application
exec java -jar -Dspring.profiles.active=docker app.jar


