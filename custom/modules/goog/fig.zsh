function rmuntr() {
    hg st -un | xargs rm
}

function revert() {
    echo "[info] hg revert -r p4head $1"
    hg revert -r p4head $1
}

function opencl() {
  xdg-open "http://cl/$(hg exportedcl)"
}

function sg_reset() {
  echo "Resetting current Fig workspace..."

  # Drop all pending CLs and prune their associated commits from this workspace.
  # "exported()" selects commits that have an associated CL.
  # "not public()" excludes commits that have already been submitted.
  echo "Dropping all pending (non-submitted) CLs in this workspace..."
  hg cls-drop --prune -r "exported() and not public()"

  # Revert any lingering uncommitted changes in the working directory.
  echo "Reverting any uncommitted changes..."
  hg update --clean .

  # Make the new modification.
  local random_val=$RANDOM
  echo "Modifying file..."
  echo "$random_val" >> search/frontend/silk/apis/aimode/service.textproto

  # Add the file to ensure it's tracked (important if it was somehow untracked).
  hg add search/frontend/silk/apis/aimode/service.textproto

  # Create a new commit.
  echo "Creating new commit..."
  hg commit -m "[Silk] [DNS] Testing CL (checkpoint: $random_val)"

  # Upload the current commit chain to create a new CL.
  echo "Uploading new CL..."
  hg upload chain

  echo "Fig workspace reset complete."
}

# Optional: To make the function available in your shell,
# add the above code to your ~/.zshrc file and run source ~/.zshrc
