#!/usr/bin/env bash
# init-project.sh — Initialize Aegis structure in a project
#
# Usage: bash init-project.sh /path/to/project
#
# Creates:
#   contracts/api-spec.yaml
#   contracts/shared-types.ts
#   contracts/errors.yaml
#   docs/designs/.gitkeep

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES="$SKILL_DIR/templates"

PROJECT="${1:-.}"

if [[ ! -d "$PROJECT" ]]; then
  echo "Error: Project directory '$PROJECT' does not exist."
  exit 1
fi

echo "🛡️  Initializing Aegis structure in: $PROJECT"

# Create directories
mkdir -p "$PROJECT/contracts"
mkdir -p "$PROJECT/docs/designs"

# Copy templates (don't overwrite existing)
copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [[ -f "$dest" ]]; then
    echo "  ⏭️  Skipped (exists): $dest"
  else
    cp "$src" "$dest"
    echo "  ✅ Created: $dest"
  fi
}

copy_if_missing "$TEMPLATES/api-spec-starter.yaml" "$PROJECT/contracts/api-spec.yaml"
copy_if_missing "$TEMPLATES/shared-types-starter.ts" "$PROJECT/contracts/shared-types.ts"
copy_if_missing "$TEMPLATES/errors-starter.yaml" "$PROJECT/contracts/errors.yaml"

# Create .gitkeep for empty dirs
touch "$PROJECT/docs/designs/.gitkeep"

# If CLAUDE.md doesn't exist, offer the template
if [[ ! -f "$PROJECT/CLAUDE.md" ]]; then
  cp "$TEMPLATES/claude-md.md" "$PROJECT/CLAUDE.md"
  echo "  ✅ Created: CLAUDE.md (from Aegis template — customize it!)"
else
  echo "  ⏭️  Skipped (exists): CLAUDE.md"
fi

echo ""
echo "🛡️  Aegis initialized! Next steps:"
echo "  1. Edit contracts/api-spec.yaml with your API endpoints"
echo "  2. Customize CLAUDE.md for your project"
echo "  3. Create your first Design Brief in docs/designs/"
echo ""
echo "  Template: $TEMPLATES/design-brief.md"
