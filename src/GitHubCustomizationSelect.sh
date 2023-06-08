#!/bin/bash # script GitHubCustomizationSelect.sh

BUILD_DIR=~/Downloads/BuildLoop

#!inline patch_functions.sh

############################################################
# The rest of this is specific to the particular script
############################################################

add_customization "CAGE: Upload Pod Start to Nightscout" "omnipod_cage"
add_customization "SAGE: Upload Dexcom Sensor Start to Nightscout" "dexcom_sage"
add_customization "Change Default to Upload Dexcom Readings" "dexcom_upload_readings"
add_customization "Increase Future Carbs Limit to 4 hours" "future_carbs_4h"
add_customization "Modify Carb Warning & Limit: Low Carb to 49 & 99" "low_carb_limit"

add_customization "Modify Carb Warning & Limit: High Carb to 201 & 300" "high_carb_limit"
add_customization "Disable Authentication Requirement" "no_auth"
add_customization "Override Insulin Needs Picker (50% to 200%, steps of 5%)" "override_sens"
add_customization "Libre Users: Limit Loop to 5 minute update" "limit_loop_cycle_time"
add_customization "Modify Logo with LnL icon" "lnl_icon"

add_customization "CustomTypeOne LoopPatches (original)" "customtypeone_looppatches"
# 2023-06-05 rearrangement note:
#   PR 2002 is first to encourage people to update it first
#           - it must be updated before PR 1988 update is valid
add_customization "Profiles (PR 2002)" "profile"
add_customization "Glucose Based Application Factor (PR 1988)" "ab_ramp"
add_customization "Glucose Based Application Factor (PR 1988) with Modified CustomTypeOne LoopPatches" "ab_ramp_cto"

download_patches

for arg in "$@"
do
    for i in "${!folder[@]}"
    do
        if [[ "${folder[$i]}" == "$arg" ]]
        then
            apply_patch_github "$i"
            break
        fi
    done
done