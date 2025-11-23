cat > scripts/ci-check.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "[CI] Running basic sanity checks..."

# 1. Ensure required directories exist
for dir in manifests image dotfiles scripts; do
  if [ ! -d "$dir" ]; then
    echo "[CI] ERROR: Missing directory: $dir"
    exit 1
  fi
done

# 2. Ensure key manifest files exist
for mf in manifests/apt-packages.base.txt manifests/apt-packages.gui.txt; do
  if [ ! -f "$mf" ]; then
    echo "[CI] ERROR: Missing manifest: $mf"
    exit 1
  fi
done

echo "[CI] All basic checks passed."
EOF

chmod +x scripts/ci-check.sh