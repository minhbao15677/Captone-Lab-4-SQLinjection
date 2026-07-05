#!/bin/bash
set -e

# Run the original WordPress entrypoint in background
/usr/local/bin/docker-entrypoint.sh apache2-foreground &
APACHE_PID=$!

echo "[IPMAC] Waiting for WordPress files to be ready..."
# wp-settings.php is created by the official WP entrypoint
until [ -f /var/www/html/wp-settings.php ]; do
    sleep 3
done

echo "[IPMAC] WordPress files ready. Waiting for MySQL..."
# Wait for DB via wp cli
until /usr/local/bin/wp --allow-root --path=/var/www/html db check 2>/dev/null; do
    sleep 5
done

echo "[IPMAC] MySQL ready. Running setup script..."
bash /setup.sh

echo "[IPMAC] ✅ Setup complete — serving on cafeipmac.local"
wait $APACHE_PID
