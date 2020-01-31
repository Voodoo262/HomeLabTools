#!/bin/sh

# CloneVM.sh
# This script will copy an existing VM folder and rename all relevant files within.
# This is useful if you have a datastore with a repository of VM templates and you
# want to create a new instance of an existing template. It will change the name
# of the VM to the new name you specify, then update the disk, snapshot, and config
# files to reference the new file names
#
# Tested on ESXI 6.7.0 Update 3 (Build 14320388)
#
# Some code borrowed from https://github.com/alt250/Sundry/blob/whitespacefix/CloneVM.sh

SOURCE_DIR=$(pwd)
TARGET_DIR="/vmfs/volumes/NVMe Pool/VMs"

# Check syntax
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 SOURCE TARGET" >&2
    exit 1
fi

# Check source directory
if [ ! -d "$1" ]; then
    echo "Invalid source directory" >&2
    exit 1
fi

# Copy recursively
echo "Copying $1 to $TARGET_DIR/$2 ..."
cp -r "$1" "$TARGET_DIR/$2"
if [ $? -ne 0 ]; then
    echo "Copy failed"
    exit 1
fi

# Rename files
cd "$TARGET_DIR/$2"
for file in *; do
    if [[ "${file}" != "${file/$1/$2}" ]]; then
        echo "Renaming ${file} to ${file/$1/$2} ..."
        mv -i "${file}" "${file/$1/$2}"
    fi
done

# Replace VM references in VMDK files
echo "Updating VMDK files..."
VMDK_LIST=$(ls *.vmdk | grep -v "\-flat.vmdk" | grep -v "\-sesparse.vmdk")
for VMDK in "${VMDK_LIST}"; do
    sed -i "s/$1/$2/g" "$VMDK"
done

# Replace VM references in snapshot file
echo "Updating snapshot file..."
sed -i "s/$1/$2/g" "${2}.vmsd"

# Replace VM references in VM config file
echo "Updating VM config file..."
sed -i "s/$1/$2/g" "${2}.vmx"

echo "Success!"
