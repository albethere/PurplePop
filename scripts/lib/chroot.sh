#!/usr/bin/env bash

# shellcheck shell=bash

# Helper functions for mounting and tearing down chroot bind mounts.
# Functions are intentionally simple and avoid modifying shell options so they can
# be safely sourced from other scripts.

mount_chroot_binds() {
  local root="$1"

  mkdir -p "${root}/dev" "${root}/dev/pts" "${root}/proc" "${root}/sys" "${root}/run"

  if ! mountpoint -q "${root}/dev"; then
    mount --bind /dev "${root}/dev"
  fi

  if ! mountpoint -q "${root}/dev/pts"; then
    mount --bind /dev/pts "${root}/dev/pts"
  fi

  if ! mountpoint -q "${root}/proc"; then
    mount --types proc /proc "${root}/proc"
  fi

  if ! mountpoint -q "${root}/sys"; then
    mount --types sysfs /sys "${root}/sys"
  fi

  if ! mountpoint -q "${root}/run"; then
    mount --bind /run "${root}/run"
  fi
}

teardown_chroot_binds() {
  local root="$1"

  for mnt in run sys proc dev/pts dev; do
    local path="${root}/${mnt}"
    if mountpoint -q "${path}"; then
      umount "${path}" || true
    fi
  done
}