#!/usr/bin/env bash
# setup-repo.sh
# Used to configure a repo for formatting, and adds a precommit hook to check formatting.
# Copyright 2015 Square, Inc

set -ex
export CDPATH=""
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pre_commit_file='.git/hooks/pre-commit';

function ensure_pre_commit_file_exists() {
  if [ -e "$pre_commit_file" ]; then
    return 0
  fi 
  # It's a symlink
  if [ -h "$pre_commit_file" ]; then
    pre_commit_file=$(readlink "$pre_commit_file")
    return 0
  fi 

  if [ -d ".git" ]; then
    $(mkdir -p ".git/hooks");
  elif [ -e ".git" ]; then
    # grab the git dir from our .git file, listed as 'gitdir: blah/blah/foo'
    git_dir=$(grep gitdir .git | cut -d ' ' -f 2)
    pre_commit_file="$git_dir/hooks/pre-commit"
  else
    $(mkdir -p ".git/hooks");
  fi

  $(touch $pre_commit_file)
}

function ensure_pre_commit_file_is_executable() {
  $(chmod +x "$pre_commit_file")
}

function ensure_hook_is_installed() {
  # check if this repo is referenced in the precommit hook already
  repo_path=$(git rev-parse --show-toplevel)
  if ! grep -q "$repo_path" "$pre_commit_file"; then
    echo "#!/usr/bin/env bash" >> $pre_commit_file
    echo "current_repo_path=\$(git rev-parse --show-toplevel)" >> $pre_commit_file
    echo "repo_to_format=\"$repo_path\"" >> $pre_commit_file
    echo 'if [ "$current_repo_path" == "$repo_to_format" ]'" && [ -e \"$DIR\"/format-objc-hook ]; then \"$DIR\"/format-objc-hook; fi" >> $pre_commit_file
  fi
}

function ensure_git_ignores_clang_format_file() {
  # if .clang-format is already in the git tree then it doesn't need to be added to the ignore file
  pushd "$DIR"
  git ls-files .clang-format --error-unmatch > /dev/null
  in_tree=$?
  popd
  grep -q ".clang-format" ".gitignore"
  if [ $? -gt 0 -a $in_tree -gt 0 ]; then
    echo ".clang-format" >> ".gitignore"
  fi
}

function symlink_clang_format() {
  # only symlink .clang-format if it doesn't exist already
  if [ ! -e "$DIR/.clang-format" ]; then
    $(ln -sf "$DIR/.clang-format" ".clang-format")
  fi
}


ensure_pre_commit_file_exists && ensure_pre_commit_file_is_executable && ensure_hook_is_installed && ensure_git_ignores_clang_format_file && symlink_clang_format

