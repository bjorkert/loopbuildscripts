#!/bin/bash

## copy from helper_functions.sh to beginning of scripts

############################################################
# define some font styles and colors
############################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

############################################################
# set up nominal values
#   these can be later overwritten by flags
#   for convenience when testing (or for advanced usersS)
############################################################

# FRESH_CLONE
#   Default value is 1, which means:
#     Download fresh clone every time script is run
FRESH_CLONE=1

# BRANCH_TYPE
#   This determines the branch for git clone command
#   Default value is master
BRANCH_TYPE=master

# Prepare date-time stamp for folder
LOOP_BUILD=$(date +'%y%m%d-%H%M')

function usage() {
    echo -e "Allowed arguments:"
    echo -e "  -h or --help : print this help message"
    echo -e "  -t or --test : sets FRESH_CLONE=0"
    echo -e "      To test script, execute while in folder "
    echo -e "          between BuildLoop and LoopWorkspace"
    echo -e "  -d or --dev  : use dev branches (not master)"
}

############################################################
# Process flags, input options as positional parameters
############################################################
while [ "$1" != "" ]; do
    case $1 in
        -h | --help ) # usage function for help
            usage
            exit
            ;;
        -t | --test )  # Do not download clone - useful for testing
            echo -e "  -t or --test selected, sets FRESH_CLONE=0"
            FRESH_CLONE=0
            ;;
        -d | --dev )  # select dev branches
            echo -e "  -d or --dev selected, sets BRANCH_TYPE=dev"
            BRANCH_TYPE=dev
            LOOP_BUILD="dev"-${LOOP_BUILD}
            ;;
        * )  # argument not recognized
            echo -e "\n${RED}${BOLD}Input argument not recognized${NC}\n"
            usage
            exit 1
    esac
    shift
done

sleep 1

############################################################
# Define the rest of the functions (usage defined above):
############################################################

function initial_greeting() {
    echo -e "${RED}${BOLD}\n\n--------------------------------\n\n"
    echo -e "IMPORTANT\n"
    echo -e "Please understand that this project:\n"
    echo -e "- Is Open Source software"
    echo -e "- Is not \"approved\" for therapy\n"
    echo -e "And that:"
    echo -e "- You take full responsibility for"
    echo -e "  reading and understanding the documenation"
    echo -e "  (LoopsDocs is found at https://loopdocs.org)"
    echo -e "  before building and running this system,"
    echo -e "  and do so at your own risk.\n"
    echo -e "${NC}If you find the font too small to read comfortably"
    echo -e "  Hold down the CMD key and hit + (or -)"
    echo -e "  to increase (decrease) size"
    accept_or_cancel
}

function accept_or_cancel() {
    echo -e "\n${RED}${BOLD}By typing 1 and ENTER, you indicate you agree"
    echo -e "  Any other entry cancels"
    echo -e "\n--------------------------------\n${NC}"
}

function choose_or_cancel() {
    echo -e "\nType a number from the list below and return to proceed."
    echo -e "${RED}${BOLD}  To cancel, any entry not in list also works${NC}"
    echo -e "\n--------------------------------\n"
}

function cancel_entry() {
    echo -e "\n${RED}${BOLD}User canceled${NC}\n"
    exit_message
}

function invalid_entry() {
    echo -e "\n${RED}${BOLD}User canceled by entering an invalid option${NC}\n"
    exit_message
}

function exit_message() {
    echo -e "You can press the up arrow ⬆️  on the keyboard"
    echo -e "    and return to repeat script from beginning.\n\n";
    exit 0
}

function return_when_ready() {
    read -p "Return when ready to continue  " dummy
}

############################################################
# function configure_folders_download_script
#
# defines folder names and default locations
# downloads copy of this script (main branch)
#
# This function call should be AFTER user accepts terms of use
#    DO NOT MOVE call to this function before that question
#
############################################################
function configure_folders_download_script() {

    LOOP_DIR=~/Downloads/BuildLoop/
    SCRIPT_DIR=~/Downloads/BuildLoop/Scripts

    if [ ! -d ${LOOP_DIR} ]; then
        mkdir $LOOP_DIR
    fi
    if [ ! -d ${SCRIPT_DIR} ]; then
        mkdir $SCRIPT_DIR
    fi

    # store a copy of this script in script directory
    curl -fsSLo ${SCRIPT_DIR}/BuildLoop.sh https://raw.githubusercontent.com/loopnlearn/LoopBuildScripts/main/BuildLoop.sh
}

function report_persistent_config_override() {
    echo -e "The file used by Xcode to sign your app is found at:"
    echo -e "   ~/Downloads/BuildLoop/LoopConfigOverride.xcconfig"
    echo -e "The last 3 lines of that file are shown next:\n"
    tail -3 ~/Downloads/BuildLoop/LoopConfigOverride.xcconfig
    echo -e "\nIf the last line has your Apple Developer ID"
    echo -e "   with no slashes at the beginning of the line"
    echo -e "   your targets will be automatically signed"
    echo -e "Any line that starts with // is ignored"
    echo -e "  If ID is OK, hit return"
    echo -e "  If ID is not OK, you can edit the file\n"
    return_when_ready
}

function create_persistent_config_override() {
    echo -e "\n--------------------------------\n"
    echo -e "The Apple Developer page will open when you hit return"
    echo -e " * Log in if needed"
    echo -e " * If the Membership page does not show, you may need to select it"
    echo -e "     Your Apple Developer ID is the 10-character Team ID"
    echo -e " * If you already have your account open in your browser, you may need to go to the already opened page"
    echo -e " * Once you get your ID, return to terminal window"
    echo -e "This is the page that will open after you hit return:"
    echo -e "   https://developer.apple.com/account/#!/membership\n"
    return_when_ready
    open "https://developer.apple.com/account/#!/membership"
    echo -e "\n * Click in terminal window"
    read -p "Enter the ID and return: " devID
    echo -e "\n--------------------------------\n"
    if [ ${#devID} -ne 10 ]; then
        echo -e "Something was wrong with entry"
        echo -e "You can manually sign each target in Xcode"
    else 
        echo -e "Creating ~/Downloads/BuildLoop/LoopConfigOverride.xcconfig"
        echo -e "   with your Apple Developer ID\n"
        cp -p LoopConfigOverride.xcconfig ~/Downloads/BuildLoop
        echo -e "LOOP_DEVELOPMENT_TEAM = ${devID}" >> ~/Downloads/BuildLoop/LoopConfigOverride.xcconfig
        report_persistent_config_override
        echo -e "\nXcode uses the permanent file to automatically sign your targets"
    fi
}

function check_config_override_existence_offer_to_configure() {
    echo -e "\n--------------------------------\n"
    if [ -e ~/Downloads/BuildLoop/LoopConfigOverride.xcconfig ]; then
        report_persistent_config_override
    else
        # make sure the LoopConfigOverride.xcconfig exists in clone
        if [ -e LoopConfigOverride.xcconfig ]; then
            echo -e "Choose to enter Apple Developer ID or wait and Sign Manually (later in Xcode)"
            echo -e "\nIf you choose Apple Developer ID, script will help you find it"
            choose_or_cancel
            options=("Enter Apple Developer ID" "Sign Manually" "Cancel")
            select opt in "${options[@]}"
            do
                case $opt in
                    "Enter Apple Developer ID")
                        create_persistent_config_override
                        break
                        ;;
                    "Sign Manually")
                        break
                        ;;
                    "Cancel")
                        cancel_entry
                        ;;
                      *) # Invalid option
                         invalid_entry
                         ;;
                esac
            done
        else
            echo -e "This project requires you to sign the targets individually"
            LOOPCONFIGOVERRIDE_VALID=0
        fi
    fi
    echo -e "\n--------------------------------\n"
}

############################################################
# End of functions used by script
#    - end of helper_functions.sh common code
############################################################

############################################################
# begin script specific to BuildLoopFixedDev.sh
############################################################

# Stable Dev SHA
BRANCH_TYPE=dev
LOOP_DEV_STABLE_SHA=d140675
LOOP_DEV_STABLE_DATE="July 30, 2022"
FAPS_DEV_STABLE_SHA=be189b0
FAPS_DEV_STABLE_DATE="June 28, 2022"
FIXED_SHA=0

# call function
initial_greeting

options=("Agree" "Cancel")
select opt in "${options[@]}"
do
    case $opt in
        "Agree")
            break
            ;;
        "Cancel")
            echo -e "\n${RED}${BOLD}User did not agree to terms of use.${NC}\n\n";
            exit_message
            ;;
        *)
            echo -e "\n${RED}${BOLD}User did not agree to terms of use.${NC}\n\n";
            exit_message
            ;;
    esac
done

# user agreed; call function
#    DO NOT MOVE call to configure_folders_download_script
#       before user agrees to terms of use
configure_folders_download_script

echo -e "${NC}\n\n\n\n"


echo -e "\n--------------------------------\n"
BRANCH_LOOP=dev
BRANCH_FREE=freeaps_dev
LOOPCONFIGOVERRIDE_VALID=1
echo -e "\n ${RED}${BOLD}You are running the script for the development version${NC}\n"
echo -e " -- If you choose Loop,    branch is ${RED}${BOLD}${BRANCH_LOOP}${NC}"
echo -e " -- If you choose FreeAPS, branch is ${RED}${BOLD}${BRANCH_FREE}${NC}\n"
echo -e " ${RED}${BOLD}Be aware that a development version may require frequent rebuilds${NC}\n"
echo -e " If you have not read this section of LoopDocs - please review before continuing"
echo -e "    https://loopkit.github.io/loopdocs/faqs/branch-faqs/#loop-development"
echo -e "\nThis script chooses a version (commit) of the development branch"
echo -e "    that has been built and lightly tested by the loop and learn team"
echo -e "    Both Loop and FreeAPS development branches support the use of DASH.\n"
echo -e "${RED}${BOLD}Loop    development branch version:"
echo -e "     ${LOOP_DEV_STABLE_DATE} workspace revision ${LOOP_DEV_STABLE_SHA}"
echo -e "FreeAPS development branch version:"
echo -e "     ${FAPS_DEV_STABLE_DATE} workspace revision ${FAPS_DEV_STABLE_SHA}"
echo -e "${NC}\nBefore you begin, please ensure that"
echo -e "  you have Xcode and Xcode command line tools installed, and"
echo -e "  your phone is plugged into your computer\n"
echo -e "Please select which version of Loop you would like to download and build.\n"

choose_or_cancel
options=("Loop dev tested" "FreeAPS dev tested" "Cancel")
select opt in "${options[@]}"
do
    case $opt in
        "Loop dev tested")
            FOLDERNAME=Loop'_dev_'${LOOP_DEV_STABLE_SHA}
            REPO=https://github.com/LoopKit/LoopWorkspace
            BRANCH=dev
            FIXED_SHA=$LOOP_DEV_STABLE_SHA
            LOOPCONFIGOVERRIDE_VALID=1
            break
            ;;
        "FreeAPS dev tested")
            FOLDERNAME=FreeAPS'_dev_'${FAPS_DEV_STABLE_SHA}
            REPO=https://github.com/loopnlearn/LoopWorkspace
            BRANCH=freeaps_dev
            FIXED_SHA=$FAPS_DEV_STABLE_SHA
            LOOPCONFIGOVERRIDE_VALID=1
            break
            ;;
        "Cancel")
            cancel_entry
            ;;
        *)
            invalid_entry
            ;;
    esac
done

LOOP_DIR=~/Downloads/BuildLoop/$FOLDERNAME-$LOOP_BUILD
if [ ${FRESH_CLONE} == 1 ]; then
    mkdir $LOOP_DIR
    cd $LOOP_DIR
fi
echo -e "\n\n\n\n"
echo -e "\n--------------------------------\n"
if [ ${FRESH_CLONE} == 1 ]; then
    echo -e " -- Downloading ${FOLDERNAME} ${BRANCH} to your Downloads folder --"
    echo -e "      ${LOOP_DIR}\n"
    echo -e "Issuing this command:"
    echo -e "    git clone --branch=${BRANCH} --recurse-submodules ${REPO}"
    git clone --branch=$BRANCH --recurse-submodules $REPO
fi
echo -e "\n--------------------------------\n"
echo -e "🛑 Please check for errors in the window above before proceeding."
echo -e "   If there are no errors listed, code has successfully downloaded.\n"
echo -e "Type 1 and return to continue if and ONLY if"
echo -e "  there are no errors - scroll up in terminal window to look for the word error"
choose_or_cancel
options=("Continue" "Cancel")
select opt in "${options[@]}"
do
    case $opt in
        "Continue")
            cd LoopWorkspace
            echo -e "Checking out commit ${FIXED_SHA} development branch\n"
            git checkout $FIXED_SHA --recurse-submodules --quiet
            git branch
            echo -e "Continue if no errors reported"
            choose_or_cancel
            options=("Continue" "Cancel")
            select opt in "${options[@]}"
            do
                case $opt in
                    "Continue")
                        break
                        ;;
                    "Cancel")
                        cancel_entry
                        ;;
                      *) # Invalid option
                         invalid_entry
                         ;;
                esac
            done
            if [ ${LOOPCONFIGOVERRIDE_VALID} == 1 ]; then
                check_config_override_existence_offer_to_configure
            fi

            echo -e "\nThe following items will open (when you are ready)"
            echo -e "* Webpage with abbreviated build steps (Loop and Learn)"
            echo -e "* Webpage with detailed build steps (LoopDocs)"
            echo -e "* Xcode ready to prep your current download for build\n"
            echo -e "     Do not forget to select Loop(Workspace)\n"
            return_when_ready
            # the helper page displayed depends on validity of persistent override
            if [ ${LOOPCONFIGOVERRIDE_VALID} == 1 ]; then
                # change this page to the one (not yet written) for persistent override
                open https://www.loopandlearn.org/workspace-build-loop
            else
                open https://www.loopandlearn.org/workspace-build-loop
            fi
            sleep 5
            if [ ${FIXED_SHA} == 0 ]; then
                open "https://loopkit.github.io/loopdocs/build/step14/#prepare-to-build"
            else
                open "https://loopkit.github.io/loopdocs/build/step13/#signing-loop-dev"
            fi
            sleep 5
            xed .
            echo -e "\nShell Script Completed\n"
            echo -e " * You may close the terminal window now if you want"
            echo -e "  or"
            echo -e " * You can press the up arrow ⬆️  on the keyboard"
            echo -e "    and return to repeat script from beginning.\n\n";
            exit 0
            break
            ;;
        "Cancel")
            cancel_entry
            ;;
        *)
            invalid_entry
            ;;
    esac
done
