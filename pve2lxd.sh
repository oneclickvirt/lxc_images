#!/bin/bash

apt-get update
apt-get install -y tar xz-utils zstd wget
PVE_TEMPLATE_URL="http://download.proxmox.com/images/system/"
files=(
  "almalinux-9-default_20221108_amd64.tar.xz"
  "rockylinux-9-default_20221109_amd64.tar.xz"
  "archlinux-base_20230608-1_amd64.tar.zst"
  "alpine-3.18-default_20230607_amd64.tar.xz"
  "centos-6-default_20191016_amd64.tar.xz"
  "centos-7-default_20190926_amd64.tar.xz"
  "centos-8-default_20201210_amd64.tar.xz"
  "centos-8-stream-default_20220327_amd64.tar.xz"
  "centos-9-stream-default_20221109_amd64.tar.xz"
  "debian-8.0-standard_8.11-1_amd64.tar.gz"
  "debian-9.0-standard_9.7-1_amd64.tar.gz"
  "debian-10-standard_10.7-1_amd64.tar.gz"
  "debian-11-standard_11.7-1_amd64.tar.zst"
  "debian-12-standard_12.0-1_amd64.tar.zst"
  "ubuntu-14.04-standard_14.04.5-1_amd64.tar.gz"
  "ubuntu-16.04-standard_16.04.5-1_amd64.tar.gz"
  "ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz"
  "ubuntu-20.04-standard_20.04-1_amd64.tar.gz"
  "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
)

for file in "${files[@]}"; do
  # Delete previous metadata.yaml file
  rm -f metadata.yaml

  wget "${PVE_TEMPLATE_URL}${file}"
  chmod 777 "${file}"

  # Extract metadata information from the filename
  filename=$(basename "$file")
  os=$(echo "$filename" | awk -F- '{print $1}')
  release=$(echo "$filename" | awk -F- '{print $2}')
  creation_date=$(date +%s)

  # Create metadata.yaml file
  cat <<EOL > metadata.yaml
architecture: "x86_64"
creation_date: $creation_date
properties:
  architecture: "x86_64"
  description: "$os $release Default Image"
  os: "$os"
  release: "$release"
EOL

  # Import image with metadata
  lxc image import "${file}" --alias "${os}-${release}" --metadata="$(pwd)/metadata.yaml"

  # Remove temporary files
  rm -f "${file}" metadata.yaml
done

# Clean up
rm -rf temp
mkdir temp
mkdir lxd
