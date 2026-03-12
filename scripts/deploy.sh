#!/usr/bin/env bash
# Deploy script - syncs build/web to production server

set -e

echo "Deploying to openclaw server..."
rsync -avz --update build/web/ openclaw:/var/www/sudoku/

echo "Deploy complete."
