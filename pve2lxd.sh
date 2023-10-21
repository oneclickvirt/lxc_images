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
  wget "${PVE_TEMPLATE_URL}${file}"
  chmod 777 "${file}"

  # Extracting information from the filename
  filename=$(basename "$file")
  os_release=$(echo "$filename" | awk -F"[-_.]" '{print $1}')
  release_version=$(echo "$filename" | awk -F"[-_.]" '{print $2}')

  # Creating metadata.yaml file
  echo "architecture: \"x86_64\"" > metadata.yaml
  echo "creation_date: $(date +%s)" >> metadata.yaml
  echo "properties:" >> metadata.yaml
  echo "  architecture: \"x86_64\"" >> metadata.yaml
  echo "  description: \"$os_release $release_version Default Image\"" >> metadata.yaml
  echo "  os: \"$os_release\"" >> metadata.yaml
  echo "  release: \"$release_version\"" >> metadata.yaml

  # Creating image folder
  mkdir -p "temp/$os_release-$release_version"

  # Extracting and converting image
  if [[ $file == *.tar.xz ]]; then
    xz -d "$file"
    tar -xvf "${filename%.tar.xz}.tar" -C "temp/$os_release-$release_version"
    rm -rf "${filename%.tar.xz}.tar"
  elif [[ $file == *.tar.zst ]]; then
    unzstd "$file" -o "${filename%.tar.zst}.tar"
    tar -xvf "${filename%.tar.zst}.tar" -C "temp/$os_release-$release_version"
    rm -rf "${filename%.tar.zst}.tar"
  elif [[ $file == *.tar.gz ]]; then
    tar -xvf "$file" -C "temp/$os_release-$release_version"
  fi

  # Creating a new compressed tarball
  tar -zcf "${filename%.tar*}.tar.gz" "temp/$os_release-$release_version"

  # Moving files
  mkdir -p "lxd/$os_release-$release_version"
  mv "${filename%.tar*}.tar.gz" "lxd/$os_release-$release_version/"
  tar -czvf meta.tar.gz metadata.yaml
  mv meta.tar.gz "lxd/$os_release-$release_version/"
  
  # Cleaning up temporary files
  rm -rf "temp/$os_release-$release_version"
  rm -rf meta.tar.gz metadata.yaml
done

# Cleaning up
rm -rf temp metadata.yaml
rm -rf *.tar.*
