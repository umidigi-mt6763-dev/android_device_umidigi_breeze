#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=breeze
VENDOR=umidigi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/bin/hw/android.hardware.wifi@1.0-service-mediatek)
            "${PATCHELF}" --add-needed "libcompiler_rt.so" "${2}"
            "${PATCHELF}" --replace-needed "libwifi-hal.so" "libwifi-hal-mtk.so" "${2}"
            ;;
        vendor/bin/hw/hostapd)
            "${PATCHELF}" --add-needed "libcompiler_rt.so" "${2}"
            "${PATCHELF}" --replace-needed "libc++.so" "libc++-v28.so" "${2}"
            "${PATCHELF}" --replace-needed "libhwbinder.so" "libhwbinder-v28.so" "${2}"
            ;;
        vendor/bin/hw/wpa_supplicant)
            "${PATCHELF}" --add-needed "libcompiler_rt.so" "${2}"
            "${PATCHELF}" --replace-needed "libc++.so" "libc++-v28.so" "${2}"
            ;;
        vendor/lib/hw/android.hardware.audio@4.0-impl-mediatek.so)
            "${PATCHELF}" --replace-needed "android.hardware.audio.common@4.0-util.so" "android.hardware.audio.common@4.0-util-v28.so" "${2}"
            ;;
        vendor/lib/hw/audio.primary.mt6763.so)
            "${PATCHELF}" --replace-needed "libmedia_helper.so" "libmedia_helper-v28.so" "${2}"
            "${PATCHELF}" --replace-needed "libxml2.so" "libxml2-v28.so" "${2}"
            ;;
        vendor/lib/libMtkOmxVdecEx.so)
            "${PATCHELF}" --replace-needed "libui.so" "libui-v28.so" "${2}"
            ;;
        vendor/lib64/hw/gatekeeper.itrusty.so)
            "${PATCHELF}" --replace-needed "libgatekeeper.so" "libgatekeeper-v28.so" "${2}"
            ;;
        vendor/lib64/hw/keystore.itrusty.so)
            "${PATCHELF}" --replace-needed "libkeymaster_messages.so" "libkeymaster_messages-v28.so" "${2}"
            ;;
        vendor/lib64/libmtkcam_stdutils.so)
            "${PATCHELF}" --replace-needed "libutils.so" "libutils-v30.so" "${2}"
            ;;
        vendor/lib64/libmtk-ril.so)
            sed -i 's|AT+EAIC=2|AT+EAIC=3|g' "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
