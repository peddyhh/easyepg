#!/bin/bash
# shellcheck disable=SC1003
#set -eu -o pipefail

#      Copyright (C) 2019-2020 Jan-Luca Neumann
#      https://github.com/sunsettrack4/easyepg
#
#      Collaborators:
#      - DeBaschdi ( https://github.com/DeBaschdi )
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with easyepg. If not, see <http://www.gnu.org/licenses/>.

clear
echo " ----------------------------------------------"
echo " EASYEPG SIMPLE XMLTV GRABBER                  "
echo " Release v0.4.3 BETA                           "
echo " powered by                                    "
echo "                                               "
echo " ==THE=======================================  "
echo "   ##### ##### ##### #   # ##### ##### #####   "
echo "   #     #   # #     #   # #     #   # #       "
echo "  ##### ##### ##### #####  ##### ##### #  ##   "
echo "  #     #   #     #   #    #     #     #   #   "
echo " ##### #   # #####   #     ##### #     #####   "
echo " ===================================PROJECT==  "
echo "                                               "
echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4 "
echo " ----------------------------------------------"
echo ""


# ################
# Variables
# ################
PID=$$
SCRIPT="$0"
# TAGTIME=$(date +"%Y%m%d%H%M%S")
PROJECTDIR="$(cd "${0%/*}" ; pwd)"
# PROJECTDIR_ABS=$(cd ${0%/*}/.. ; pwd -P)
BASETMPDIR="${BASETMPDIR:-"/tmp"}"
TMPDIR="${TMPDIR:-"$BASETMPDIR/$PID"}"
PROVIDERLIST="${PROVIDERLIST:-"hzn ztt swc tvp tkm rdt wpu tvs vdf tvtv ext"}"
TOOLLIST="dialog curl wget phantomjs xmllint  perl perldoc cpan jq php git"
PERLMODULES="JSON XML::Rules XML::DOM Data::Dumper Time::Piece Time::Seconds utf8 DateTime DateTime::Format::DateParse DateTime::Format::Strptime"
## SET OLDPWD VALUE
STARTDIR="$(pwd)"
# echo "DIR=$(pwd)" > "${TMPDIR}/initrun.txt"
# echo "VER=peddyhh" >> "${TMPDIR}/initrun.txt"
ERROR=""

export SCRIPT PROJECTDIR TMPDIR STARTDIR PROVIDERLIST TOOLLIST PERLMODULES ERROR
echo "$SCRIPT -- $STARTDIR -- $PROJECTDIR -- $TMPDIR"



# #############################################################################
# clean up on normal exit or failure
# #############################################################################
function cleanup() {
    if [ -n "$TMPDIR" ]; then rm -rf "$TMPDIR"; fi
    if [ -n "$ERROR" ]; then echo "ERROR failure occure ... exit"; exit 1; fi
}

# ################
# INITIALIZATION #
# ################
printf "Initializing script environment..."

#
#  FIX DIRECTORY AND FILE RIGHTS
#

## TODO: auslagern in install.sh
if ! find "$PROJECTDIR" ! -iname "combine" ! -iname "xml" -type d -exec chmod 755 {} \;
then
    printf "\nPermissions of script folder '%s' could not be set " "$PROJECTDIR"
    ERROR="true"
fi
if ! find "$PROJECTDIR" ! -iname "*.sh" ! -iname "*.pl" -type f -exec chmod 644  {} \;
then
    printf "\nPermissions of script folder '%s' could not be set " "$PROJECTDIR"
    ERROR="true"
fi
if ! find "$PROJECTDIR/" -iname "*.sh"   -type f -exec chmod 755  {} \;
then
    printf "\n%s: Permissions of shellscripts in '%s' could not be set!" "$SCRIPT" "$PROJECTDIR"
    ERROR="true"
fi
if ! find "$PROJECTDIR/" -iname "*.pl"   -type f -exec chmod 755  {} \;
then
    printf "\n%s: Permissions of perlscripts in '%s' could not be set!" "$SCRIPT" "$PROJECTDIR"
    ERROR="true"
fi

#
# Prepare TMPDIR
#
mkdir -p "${TMPDIR}"
if ! touch "${TMPDIR}/testtmp"
then
    printf "\nWorkfolder '%s' does not have write permissions  " "$TMPDIR"
    ERROR="true"
fi


#
# CHECK IF ALL MAIN SCRIPTS AND FOLDERS EXIST
#
SCRIPTFILES="
    hzn/ch_json2xml.pl
    hzn/cid_json.pl
    hzn/epg_json2xml.pl
    hzn/chlist_printer.pl
    hzn/settings.sh
    hzn/compare_menu.pl
    hzn/hzn.sh

    ztt/ch_json2xml.pl
    ztt/chlist_printer.pl
    ztt/cid_json.pl
    ztt/compare_crid.pl
    ztt/compare_menu.pl
    ztt/epg_json2xml.pl
    ztt/settings.sh
    ztt/ztt.sh

    swc/ch_json2xml.pl
    swc/chlist_printer.pl
    swc/cid_json.pl
    swc/compare_menu.pl
    swc/epg_json2xml.pl
    swc/settings.sh
    swc/swc.sh
    swc/url_printer.pl

    tvp/ch_json2xml.pl
    tvp/chlist_printer.pl
    tvp/cid_json.pl
    tvp/compare_menu.pl
    tvp/epg_json2xml.pl
    tvp/settings.sh
    tvp/tvp.sh

    tkm/ch_json2xml.pl
    tkm/chlist_printer.pl
    tkm/proxy.sh
    tkm/cid_json.pl
    tkm/compare_menu.pl
    tkm/epg_json2xml.pl
    tkm/settings.sh
    tkm/tkm.sh

    rdt/ch_json2xml.pl
    rdt/chlist_printer.pl
    rdt/cid_json.pl
    rdt/compare_crid.pl
    rdt/compare_menu.pl
    rdt/epg_json2xml.pl
    rdt/rdt.sh
    rdt/settings.sh
    rdt/url_printer.pl

    wpu/ch_json2xml.pl
    wpu/chlist_printer.pl
    wpu/cid_json.pl
    wpu/compare_menu.pl
    wpu/epg_json2xml.pl
    wpu/settings.sh
    wpu/wpu.sh


    tvs/ch_json2xml.pl
    tvs/chlist_printer.pl
    tvs/cid_json.pl
    tvs/compare_menu.pl
    tvs/epg_json2xml.pl
    tvs/settings.sh
    tvs/tvs.sh

    vdf/ch_json2xml.pl
    vdf/chlist_printer.pl
    vdf/cid_json.pl
    vdf/compare_menu.pl
    vdf/epg_json2xml.pl
    vdf/settings.sh
    vdf/vdf.sh

    tvtv/ch_json2xml.pl
    tvtv/chlist_printer.pl
    tvtv/cid_json.pl
    tvtv/compare_crid.pl
    tvtv/compare_menu.pl
    tvtv/epg_json2xml.pl
    tvtv/settings.sh
    tvtv/tvtv.sh
    tvtv/url_printer.pl

    ext/ch_ext.pl
    ext/compare_menu.pl
    ext/epg_ext.pl
    ext/ext.sh
    ext/settings.sh

    combine.sh
    ch_combine.pl
    prog_combine.pl
    backup.sh
    restore.sh
"
while read -r SF; do
    # echo "== $SF ==";
    if [ -n "$SF" ]; then
        if ! test -x "$SF"; then
            printf "\n%s: file '%s' is missing or not executable" "$SCRIPT" "$SF"
            ERROR="true"
        fi
    fi
done <<<"$SCRIPTFILES"

OTHERFILES="
    ztt/save_page.js

    tkm/web_magentatv_de.php
    tkm/web_magentatv_de.php
"
while read -r OF; do
    # echo "== $OF ==";
    if [ -n "$OF" ]; then
        if ! test -r "$OF"; then
            printf "\n%s: file '%s' is missing or not readable" "$SCRIPT" "$OF"
            ERROR="true"
        fi
    fi
done <<<"$OTHERFILES"

## CHECK IF ALL TOOLS ARE INSTALLED
for Tool in $TOOLLIST; do  command -v "$Tool" >/dev/null || { printf "\n%s: ERROR: missing command '%s'" "$SCRIPT" "$Tool"; ERROR=true; } ; done

if ! php -m |grep curl >/dev/null 2>&1
then
        printf "\nphp-curl is required but it's not installed!" >&2; ERROR="true";
fi

## CHECK installed perlmodules
if command -v perldoc >/dev/null
then
    for PerlModule in $PERLMODULES; do
        perldoc -l "$PerlModule" >/dev/null 2>&1 || { printf "\n  %s module for perl is requried but not installed!" "$PerlModule" >&2 ; ERROR="true"; }
    done
else
    printf "\n'perldoc' is required but not installed!"
    ERROR="true"
fi


#
# CHECK INTERNET CONNECTIVITY
#
# if ! ping -q -w 1 -c 1 "$(ip r | grep default | cut -d ' ' -f 3)" > /dev/null 2> /dev/null
case "$(uname)" in
    Darwin) PINGPARAM='-t1'  ;;
    Linux)  PINGPARAM='-w1'  ;;
esac

# shellcheck disable=SC2086
if ! ping -q -c 1 $PINGPARAM "8.8.8.8" > /dev/null 2> /dev/null
then
    printf "\n\n[ WARNING ] Internet connection check failed!      \n"
    sleep 2s
fi


#
# FINAL MESSAGE
#
if [ -n "$ERROR" ]
then
    printf "\n\n[ FATAL ERROR ] Script environment is broken - Stop.\n"
    cleanup 1
else
    printf "\n\nSETUP OK!"
    sleep 1s
fi

# #############################################################################
# #                           functions
# #############################################################################
function grabber_mode() {
    if ls -l hzn/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " HORIZON EPG SIMPLE XMLTV GRABBER            "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd hzn/de 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/de/horizon.xml xml/horizon_de.xml 2> /dev/null
        cd hzn/at 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/at/horizon.xml xml/horizon_at.xml 2> /dev/null
        cd hzn/ch 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/ch/horizon.xml xml/horizon_ch.xml 2> /dev/null
        cd hzn/nl 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/nl/horizon.xml xml/horizon_nl.xml 2> /dev/null
        cd hzn/pl 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/pl/horizon.xml xml/horizon_pl.xml 2> /dev/null
        cd hzn/ie 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/ie/horizon.xml xml/horizon_ie.xml 2> /dev/null
        cd hzn/sk 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/sk/horizon.xml xml/horizon_sk.xml 2> /dev/null
        cd hzn/cz 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/cz/horizon.xml xml/horizon_cz.xml 2> /dev/null
        cd hzn/hu 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/hu/horizon.xml xml/horizon_hu.xml 2> /dev/null
        cd hzn/ro 2> /dev/null && bash hzn.sh && cd - > /dev/null && cp hzn/ro/horizon.xml xml/horizon_ro.xml 2> /dev/null
    fi

    if ls -l ztt/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " ZATTOO EPG SIMPLE XMLTV GRABBER             "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd ztt/de 2> /dev/null && bash ztt.sh && cd - > /dev/null && cp ztt/de/zattoo.xml xml/zattoo_de.xml 2> /dev/null
        cd ztt/ch 2> /dev/null && bash ztt.sh && cd - > /dev/null && cp ztt/ch/zattoo.xml xml/zattoo_ch.xml 2> /dev/null
    fi

    if ls -l swc/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " SWISSCOM EPG SIMPLE XMLTV GRABBER           "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd swc/ch 2> /dev/null && bash swc.sh && cd - > /dev/null && cp swc/ch/swisscom.xml xml/swisscom_ch.xml 2> /dev/null
    fi

    if ls -l tvp/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " TVPLAYER EPG SIMPLE XMLTV GRABBER           "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd tvp/uk 2> /dev/null && bash tvp.sh && cd - > /dev/null && cp tvp/uk/tvp.xml xml/tvplayer_uk.xml 2> /dev/null
    fi

    if ls -l tkm/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " TELEKOM EPG SIMPLE XMLTV GRABBER            "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd tkm/de 2> /dev/null && bash tkm.sh && cd - > /dev/null && cp tkm/de/magenta.xml xml/magentatv_de.xml 2> /dev/null
    fi

    if ls -l rdt/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " RADIOTIMES EPG SIMPLE XMLTV GRABBER         "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd rdt/uk 2> /dev/null && bash rdt.sh && cd - > /dev/null && cp rdt/uk/radiotimes.xml xml/radiotimes_uk.xml 2> /dev/null
    fi

    if ls -l wpu/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " WAIPU.TV EPG SIMPLE XMLTV GRABBER           "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd wpu/de 2> /dev/null && bash wpu.sh && cd - > /dev/null && cp wpu/de/waipu.xml xml/waipu_de.xml 2> /dev/null
    fi

    if ls -l tvs/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " TV-SPIELFILM EPG SIMPLE XMLTV GRABBER       "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd tvs/de 2> /dev/null && bash tvs.sh && cd - > /dev/null && cp tvs/de/tv-spielfilm.xml xml/tv-spielfilm_de.xml 2> /dev/null
    fi

    if ls -l vdf/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " VODAFONE EPG SIMPLE XMLTV GRABBER           "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd vdf/de 2> /dev/null && bash vdf.sh && cd - > /dev/null && cp vdf/de/vodafone.xml xml/vodafone_de.xml 2> /dev/null
    fi

    if ls -l tvtv/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " TVTV EPG SIMPLE XMLTV GRABBER               "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd tvtv/us 2> /dev/null && bash tvtv.sh && cd - > /dev/null && cp tvtv/us/tvtv.xml xml/tvtv_us.xml 2> /dev/null
        cd tvtv/ca 2> /dev/null && bash tvtv.sh && cd - > /dev/null && cp tvtv/ca/tvtv.xml xml/tvtv_ca.xml 2> /dev/null
    fi

    if ls -l ext/ | grep -q '^d'
    then
        echo ""
        echo " --------------------------------------------"
        echo " EXTERNAL EPG SIMPLE XMLTV GRABBER            "
        echo " powered by easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
        echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
        echo " --------------------------------------------"
        echo ""
        sleep 2s

        cd ext/oa 2> /dev/null && bash ext.sh && cd - > /dev/null && cp ext/oa/external.xml xml/external_oa.xml 2> /dev/null
        cd ext/ob 2> /dev/null && bash ext.sh && cd - > /dev/null && cp ext/ob/external.xml xml/external_ob.xml 2> /dev/null
        cd ext/oc 2> /dev/null && bash ext.sh && cd - > /dev/null && cp ext/oc/external.xml xml/external_oc.xml 2> /dev/null
    fi
} # END function grabber_mode()


##################################
function combine_xml_files () {
    ls combine > "${TMPDIR}/combinefolders" 2> /dev/null

    if [ -s "${TMPDIR}/combinefolders" ]
    then
        echo ""
        echo " --------------------------------------------"
        echo " CREATING CUSTOMIZED XMLTV FILES             "
        echo " --------------------------------------------"
        echo ""
        sleep 2s
    fi

    while [ -s "${TMPDIR}/combinefolders" ]
    do
        folder="$(sed -n "1p" "${TMPDIR}/combinefolders")"

        printf "Creating XML file: %s.xml ..." "$folder"

        if grep -q '"day": "0"' "combine/$folder/settings.json"
        then
            printf "\rCreating XML file: %s.xml ... DISABLED!\n" "$folder"
            sed -i '1d' "${TMPDIR}/combinefolders"
        else
            rm "${TMPDIR}/file" "${TMPDIR}/combined_channels" "${TMPDIR}/combined_programmes" 2> /dev/null

            # HORIZON DE
            if [ -s "combine/$folder/hzn_de_channels.json" ]
            then
                if [ -s xml/horizon_de.xml ]
                then
                    sed 's/fileNAME/horizon_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: UNITYMEDIA GERMANY -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: UNITYMEDIA GERMANY -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON AT
            if [ -s "combine/$folder/hzn_at_channels.json" ]
            then
                if [ -s xml/horizon_at.xml ]
                then
                    sed 's/fileNAME/horizon_at.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_at_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: MAGENTA T  -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_at.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_at_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: MAGENTA T -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi


            # HORIZON CH
            if [ -s "combine/$folder/hzn_ch_channels.json" ]
            then
                if [ -s xml/horizon_ch.xml ]
                then
                    sed 's/fileNAME/horizon_ch.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ch_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: UPC SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_ch.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ch_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: UPC SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON NL
            if [ -s "combine/$folder/hzn_nl_channels.json" ]
            then
                if [ -s xml/horizon_nl.xml ]
                then
                    sed 's/fileNAME/horizon_nl.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_nl_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: ZIGGO NETHERLANDS -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_nl.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_nl_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: ZIGGO NETHERLANDS -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON PL
            if [ -s "combine/$folder/hzn_pl_channels.json" ]
            then
                if [ -s xml/horizon_pl.xml ]
                then
                    sed 's/fileNAME/horizon_pl.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_pl_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: HORIZON POLAND -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_pl.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_pl_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: HORIZON POLAND -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON IE
            if [ -s "combine/$folder/hzn_ie_channels.json" ]
            then
                if [ -s xml/horizon_ie.xml ]
                then
                    sed 's/fileNAME/horizon_ie.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ie_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: VIRGIN MEDIA IRELAND -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_ie.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ie_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: VIRGIN MEDIA IRELAND -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON SK
            if [ -s "combine/$folder/hzn_sk_channels.json" ]
            then
                if [ -s xml/horizon_sk.xml ]
                then
                    sed 's/fileNAME/horizon_sk.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_sk_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: HORIZON SLOVAKIA -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_sk.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_sk_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: HORIZON SLOVAKIA -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON CZ
            if [ -s "combine/$folder/hzn_cz_channels.json" ]
            then
                if [ -s xml/horizon_cz.xml ]
                then
                    sed 's/fileNAME/horizon_cz.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_cz_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: HORIZON CZECH REPUBLIC -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_cz.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_cz_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: HORIZON CZECH REPUBLIC -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON HU
            if [ -s "combine/$folder/hzn_hu_channels.json" ]
            then
                if [ -s xml/horizon_hu.xml ]
                then
                    sed 's/fileNAME/horizon_hu.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_hu_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: HORIZON HUNGARY -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_hu.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_hu_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: HORIZON HUNGARY -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # HORIZON RO
            if [ -s "combine/$folder/hzn_ro_channels.json" ]
            then
                if [ -s xml/horizon_ro.xml ]
                then
                    sed 's/fileNAME/horizon_ro.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ro_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: HORIZON ROMANIA -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/horizon_ro.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/hzn_ro_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: HORIZON ROMANIA -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # ZATTOO DE
            if [ -s "combine/$folder/ztt_de_channels.json" ]
            then
                if [ -s xml/zattoo_de.xml ]
                then
                    sed 's/fileNAME/zattoo_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ztt_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: ZATTOO GERMANY -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/zattoo_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ztt_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: ZATTOO GERMANY -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # ZATTOO CH
            if [ -s "combine/$folder/ztt_ch_channels.json" ]
            then
                if [ -s xml/zattoo_ch.xml ]
                then
                    sed 's/fileNAME/zattoo_ch.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ztt_ch_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: ZATTOO SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/zattoo_ch.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ztt_ch_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: ZATTOO SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # SWISSCOM CH
            if [ -s "combine/$folder/swc_ch_channels.json" ]
            then
                if [ -s xml/swisscom_ch.xml ]
                then
                    sed 's/fileNAME/swisscom_ch.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/swc_ch_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: SWISSCOM SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/swisscom_ch.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/swc_ch_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: SWISSCOM SWITZERLAND -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # TVPLAYER UK
            if [ -s "combine/$folder/tvp_uk_channels.json" ]
            then
                if [ -s xml/tvplayer_uk.xml ]
                then
                    sed 's/fileNAME/tvplayer_uk.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvp_uk_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: TVPLAYER UK -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/tvplayer_uk.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvp_uk_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: TVPLAYER UK -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # MAGENTA TV DE
            if [ -s "combine/$folder/tkm_de_channels.json" ]
            then
                if [ -s xml/magentatv_de.xml ]
                then
                    sed 's/fileNAME/magentatv_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tkm_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: MAGENTA TV DE -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/magentatv_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tkm_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: MAGENTA TV DE -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # RADIOTIMES UK
            if [ -s "combine/$folder/rdt_uk_channels.json" ]
            then
                if [ -s xml/radiotimes_uk.xml ]
                then
                    sed 's/fileNAME/radiotimes_uk.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/rdt_uk_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: RADIOTIMES UK -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/radiotimes_uk.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/rdt_uk_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: RADIOTIMES UK -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # WAIPU.TV DE
            if [ -s "combine/$folder/wpu_de_channels.json" ]
            then
                if [ -s xml/waipu_de.xml ]
                then
                    sed 's/fileNAME/waipu_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/wpu_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: WAIPU.TV DE -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/waipu_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/wpu_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: WAIPU.TV DE -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # TV-SPIELFILM
            if [ -s "combine/$folder/tvs_de_channels.json" ]
            then
                if [ -s xml/tv-spielfilm_de.xml ]
                then
                    sed 's/fileNAME/tv-spielfilm_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvs_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: TV-SPIELFILM DE -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/tv-spielfilm_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvs_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: TV-SPIELFILM DE -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # VODAFONE
            if [ -s "combine/$folder/vdf_de_channels.json" ]
            then
                if [ -s xml/vodafone_de.xml ]
                then
                    sed 's/fileNAME/vodafone_de.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/vdf_de_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: VODAFONE DE -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/vodafone_de.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/vdf_de_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: VODAFONE DE -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # TVTV US
            if [ -s "combine/$folder/tvtv_us_channels.json" ]
            then
                if [ -s xml/tvtv_us.xml ]
                then
                    sed 's/fileNAME/tvtv_us.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvtv_us_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: TVTV USA -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/tvtv_us.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvtv_us_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: TVTV USA -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # TVTV CA
            if [ -s "combine/$folder/tvtv_ca_channels.json" ]
            then
                if [ -s xml/tvtv_ca.xml ]
                then
                    sed 's/fileNAME/tvtv_ca.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvtv_ca_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: TVTV CANADA -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/tvtv_ca.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/tvtv_ca_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: TVTV CANADA -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # EXTERNAL SLOT 1
            if [ -s "combine/$folder/ext_oa_channels.json" ]
            then
                if [ -s xml/external_oa.xml ]
                then
                    sed 's/fileNAME/external_oa.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_oa_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: EXTERNAL SOURCE SLOT 1 -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/external_oa.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_oa_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: EXTERNAL SOURCE SLOT 1 -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # EXTERNAL SLOT 2
            if [ -s "combine/$folder/ext_ob_channels.json" ]
            then
                if [ -s xml/external_ob.xml ]
                then
                    sed 's/fileNAME/external_ob.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_ob_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: EXTERNAL SOURCE SLOT 2 -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/external_ob.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_ob_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: EXTERNAL SOURCE SLOT 2 -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            # EXTERNAL SLOT 3
            if [ -s "combine/$folder/ext_oc_channels.json" ]
            then
                if [ -s xml/external_oc.xml ]
                then
                    sed 's/fileNAME/external_oc.xml/g' ch_combine.pl > "${TMPDIR}/ch_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_oc_channels.json/g" "${TMPDIR}/ch_combine.pl"
                    printf "\n<!-- CHANNEL LIST: EXTERNAL SOURCE SLOT 3 -->\n\n" >> "${TMPDIR}/combined_channels"
                    perl "${TMPDIR}/ch_combine.pl" >> "${TMPDIR}/combined_channels"

                    sed 's/fileNAME/external_oc.xml/g' prog_combine.pl > "${TMPDIR}/prog_combine.pl"
                    sed -i "s/channelsFILE/$folder\/ext_oc_channels.json/g" "${TMPDIR}/prog_combine.pl"
                    sed -i "s/settingsFILE/$folder\/settings.json/g" "${TMPDIR}/prog_combine.pl"
                    printf "\n<!-- PROGRAMMES: EXTERNAL SOURCE SLOT 3 -->\n\n" >> "${TMPDIR}/combined_programmes"
                    perl "${TMPDIR}/prog_combine.pl" >> "${TMPDIR}/combined_programmes"
                fi
            fi

            cat "${TMPDIR}/combined_programmes" >> "${TMPDIR}/combined_channels" 2> /dev/null && mv "${TMPDIR}/combined_channels" "${TMPDIR}/file" 2> /dev/null

            if [ -s "${TMPDIR}/file" ]
            then
                sed -i 's/\&/\&amp;/g' "${TMPDIR}/file"

                sed -i "1i<\!-- EPG XMLTV FILE CREATED BY THE EASYEPG PROJECT - (c) 2019-2020 Jan-Luca Neumann -->\n<\!-- created on $(date) -->\n<tv>" "${TMPDIR}/file"
                sed -i '1i<?xml version="1.0" encoding="UTF-8" ?>' "${TMPDIR}/file"
                sed '$s/.*/&\n<\/tv>/g' "${TMPDIR}/file" > "combine/$folder/$folder.xml"
                rm "${TMPDIR}/combined_programmes"
                sed -i '1d' "${TMPDIR}/combinefolders"

                if [ -s "combine/$folder/pre_setup.sh" ]
                then
                    printf "\n\n --------------------------------------\n\nRunning PRE SCRIPT for %s.xml ...\n\n" "$folder"
                    bash "combine/$folder/pre_setup.sh"
                    printf "\n\nDONE!\n\n"
                fi

                if [ -e "combine/$folder/run.pl" ]
                then
                    printf "\n\n --------------------------------------\n\nRunning addon: IMDB MAPPER for %s.xml ...\n\n" "$folder"
                    perl imdb/run.pl "combine/$folder/$folder.xml"  "combine/$folder/$folder_1.xml" && mv "combine/$folder/$folder_1.xml" "combine/$folder/$folder.xml"
                    printf "\n\nDONE!\n\n"
                fi

                if [ -s "combine/$folder/ratingmapper.pl" ]
                then
                    printf "\n\n --------------------------------------\n\nRunning addon: RATING MAPPER for %s.xml ...\n\n" "$folder"
                    perl "combine/$folder/ratingmapper.pl" "combine/$folder/$folder.xml" > "combine/$folder/$folder_1.xml" && mv "combine/$folder/$folder_1.xml" "combine/$folder/$folder.xml"
                    printf "\n\nDONE!\n\n"
                fi

                if [ -s "combine/$folder/setup.sh" ]
                then
                    printf "\n\n --------------------------------------\n\nRunning POST SCRIPT for %s.xml ...\n\n" "$folder"
                    bash "combine/$folder/setup\.sh"
                    printf "\n\nDONE!\n\n"
                fi

                cp "combine/$folder/$folder.xml" "xml/$folder.xml"
                printf "\rXML file %s.xml created!                            \n"  "$folder"
            else
                printf "\rCreation of XML file %s.xml failed!\nNo XML or setup file available! Please check your setup!\n"  "$folder"
                sed -i '1d' "${TMPDIR}/combinefolders"
            fi
        fi
    done
}












################################################################################################
## SET OLDPWD VALUE
# STARTDIR="$(pwd)"
echo "DIR=$(pwd)" > "${TMPDIR}/initrun.txt"
echo "VER=peddyhh" >> "${TMPDIR}/initrun.txt"

mkdir -p "$PROJECTDIR/xml"      && chmod 0777 "$PROJECTDIR/xml"
mkdir -p "$PROJECTDIR/combine"  && chmod 0777 "$PROJECTDIR/combine"





# ###############
# M1W00 CRONJOB #
# ###############
true > "${TMPDIR}/providerlist"
for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done

if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
then
    dialog  --backtitle "[M1W00] EASYEPG SIMPLE XMLTV GRABBER" \
            --title "MAIN MENU" \
            --infobox "Please press any button to enter the main menu.\n\nThe script will proceed in 5 seconds." 7 50
    if read -r -t 5 -n1
        then echo "M" > "${TMPDIR}/value"
        else echo "G" > "${TMPDIR}/value"
    fi
else
    echo "M" > "${TMPDIR}/value"
fi


# #################
# M1000 MAIN MENU #
# #################

while grep -q "M" "${TMPDIR}/value"
do
    # M1000 MENU OVERLAY
    echo 'dialog --backtitle "[M1000] EASYEPG SIMPLE XMLTV GRABBER" --title "MAIN MENU" --menu "Welcome to EasyEPG! :)\n(c) 2019-2020 Jan-Luca Neumann\n\n If you like this script, please support my work:\nhttps://paypal.me/sunsettrack4\n\nPlease choose an option:" 19 55 10 \' > "${TMPDIR}/menu"

    # M1100 ADD GRABBER
    echo '	1 "ADD GRABBER INSTANCE" \' >> "${TMPDIR}/menu"

    # M1200 GRABBER SETTINGS
    true > "${TMPDIR}/providerlist"
    for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done
    if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
    then
        echo '	2 "OPEN GRABBER SETTINGS" \' >> "${TMPDIR}/menu"
    fi

    # M1300 CREATE SINGLE-/MULTI-SOURCE XML FILE
    true > "${TMPDIR}/providerlist"
    for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done
    if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
    then
        if ls xml/ | grep -q ".xml"
        then
            echo '	3 "MODIFY XML FILES" \' >> "${TMPDIR}/menu"
        fi
    fi

    # M1400 CONTINUE IN GRABBER MODE
    true > "${TMPDIR}/providerlist"
    for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done
    if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
    then
        echo '	4 "CONTINUE IN GRABBER MODE" \' >> "${TMPDIR}/menu"
    fi

    # M1500 UPDATE
    echo '	5 "UPDATE THIS SCRIPT" \' >> "${TMPDIR}/menu"

    # M1600 BACKUP/RESTORE
    true > "${TMPDIR}/providerlist"
    for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done
    if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
    then
        echo '	6 "BACKUP / RESTORE" \' >> "${TMPDIR}/menu"
    elif [ -e easyepg_backup.zip ]
    then
        echo '	6 "BACKUP / RESTORE" \' >> "${TMPDIR}/menu"
    fi

    # M1900 ABOUT
    echo '	9 "ABOUT EASYEPG" \' >> "${TMPDIR}/menu"

    echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

    bash "${TMPDIR}/menu"
    input="$(cat "${TMPDIR}/value")"


    # ###################
    # M1100 ADD GRABBER #
    # ###################

    if grep -q "1" "${TMPDIR}/value"
    then
        {
            # M1100 MENU OVERLAY
            echo 'dialog --backtitle "[M1100] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER" --title "PROVIDERS" --menu "Please select a provider you want to use as EPG source:" 18 40 11 \' > "${TMPDIR}/menu"

            # M1110 HORIZON
            echo '	001 "HORIZON" \'
            # M1120 ZATTOO
            echo '	002 "ZATTOO" \'

            # M1130 SWISSCOM
            echo '	003 "SWISSCOM" \'

            # M1140 TVPLAYER
            echo '	004 "TVPLAYER" \'

            # M1150 TELEKOM
            echo '	005 "TELEKOM" \'

            # M1160 RADIOTIMES
            echo '	006 "RADIOTIMES" \'

            # M1170 WAIPU.TV
            echo '	007 "WAIPU.TV" \'

            # M1180 TV-SPIELFILM
            echo '	008 "TV-SPIELFILM" \'

            # M1190 VODAFONE
            echo '	009 "VODAFONE" \'

            # M11A0 TVTVUS
            echo '	010 "TVTV" \'

            # M11+0 EXTERNAL
            echo '	+ "EXTERNAL" \'
            echo "2> ${TMPDIR}/value"
        } >> "${TMPDIR}/menu"
        bash "${TMPDIR}/menu"
        input="$(cat "${TMPDIR}/value")"


        # ###############
        # M1110 HORIZON #
        # ###############

        if grep -q "001" "${TMPDIR}/value"
        then
            # M1110 MENU OVERLAY
            echo 'dialog --backtitle "[M1110] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > HORIZON" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1111 GERMANY
            if [ ! -d hzn/de ]
            then
                echo '	1 "[DE] Unitymedia Germany" \' >> "${TMPDIR}/menu"
            fi

            # M1112 AUSTRIA
            if [ ! -d hzn/at ]
            then
                echo '	2 "[AT] Magenta T" \' >> "${TMPDIR}/menu"
            fi

            # M1113 SWITZERLAND
            if [ ! -d hzn/ch ]
            then
                echo '	3 "[CH] UPC Switzerland" \' >> "${TMPDIR}/menu"
            fi

            # M1114 NETHERLANDS
            if [ ! -d hzn/nl ]
            then
                echo '	4 "[NL] Ziggo Netherlands" \' >> "${TMPDIR}/menu"
            fi

            # M1115 POLAND
            if [ ! -d hzn/pl ]
            then
                echo '	5 "[PL] Horizon Poland" \' >> "${TMPDIR}/menu"
            fi

            # M1116 IRELAND
            if [ ! -d hzn/ie ]
            then
                echo '	6 "[IE] Virgin Media Ireland" \' >> "${TMPDIR}/menu"
            fi

            # M1117 SLOVAKIA
            if [ ! -d hzn/sk ]
            then
                echo '	7 "[SK] Horizon Slovakia" \' >> "${TMPDIR}/menu"
            fi

            # M1118 CZECH REPUBLIC
            if [ ! -d hzn/cz ]
            then
                echo '	8 "[CZ] Horizon Czech Republic" \' >> "${TMPDIR}/menu"
            fi

            # M1119 HUNGARY
            if [ ! -d hzn/hu ]
            then
                echo '	9 "[HU] Horizon Hungary" \' >> "${TMPDIR}/menu"
            fi

            # M111R ROMANIA
            if [ ! -d hzn/ro ]
            then
                echo '	0 "[RO] Horizon Romania" \' >> "${TMPDIR}/menu"
            fi

            # M111E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M111E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > HORIZON" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ##################
            # M1111 HORIZON DE #
            # ##################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir hzn/de
                chmod 0777 hzn/de
                echo '{"country":"DE","language":"de"}' > hzn/de/init.json
                cp hzn/hzn.sh hzn/de/
                cp hzn/ch_json2xml.pl hzn/de/
                cp hzn/cid_json.pl hzn/de/
                cp hzn/epg_json2xml.pl hzn/de/
                cp hzn/settings.sh hzn/de/
                cp hzn/chlist_printer.pl hzn/de/
                cp hzn/compare_menu.pl hzn/de/
                sed 's/XX/DE/g;s/YYY/deu/g' hzn/url_printer.pl > hzn/de/url_printer.pl
                cd hzn/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/de/channels.json ]
                then
                    rm -rf hzn/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1112 HORIZON AT #
            # ##################

            elif grep -q "2" "${TMPDIR}/value"
            then
                mkdir hzn/at
                chmod 0777 hzn/at
                echo '{"country":"AT","language":"de"}' > hzn/at/init.json
                cp hzn/hzn.sh hzn/at/
                cp hzn/ch_json2xml.pl hzn/at/
                cp hzn/cid_json.pl hzn/at/
                cp hzn/epg_json2xml.pl hzn/at/
                cp hzn/settings.sh hzn/at/
                cp hzn/chlist_printer.pl hzn/at/
                cp hzn/compare_menu.pl hzn/at/
                sed 's/XX/AT/g;s/YYY/deu/g;s/web-api-pepper.horizon.tv/prod.oesp.magentatv.at/g' hzn/url_printer.pl > hzn/at/url_printer.pl
                cd hzn/at && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/at/channels.json ]
                then
                    rm -rf hzn/at
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1113 HORIZON CH #
            # ##################

            elif grep -q "3" "${TMPDIR}/value"
            then
                mkdir hzn/ch
                chmod 0777 hzn/ch
                echo '{"country":"CH","language":"de"}' > hzn/ch/init.json
                cp hzn/hzn.sh hzn/ch/
                cp hzn/ch_json2xml.pl hzn/ch/
                cp hzn/cid_json.pl hzn/ch/
                cp hzn/epg_json2xml.pl hzn/ch/
                cp hzn/settings.sh hzn/ch/
                cp hzn/chlist_printer.pl hzn/ch/
                cp hzn/compare_menu.pl hzn/ch/
                sed 's/XX/CH/g;s/YYY/deu/g;s/web-api-pepper.horizon.tv/obo-prod.oesp.upctv.ch/g' hzn/url_printer.pl > hzn/ch/url_printer.pl
                cd hzn/ch && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ch/channels.json ]
                then
                    rm -rf hzn/ch
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1114 HORIZON NL #
            # ##################

            elif grep -q "4" "${TMPDIR}/value"
            then
                mkdir hzn/nl
                chmod 0777 hzn/nl
                echo '{"country":"NL","language":"nl"}' > hzn/nl/init.json
                cp hzn/hzn.sh hzn/nl/
                cp hzn/ch_json2xml.pl hzn/nl/
                cp hzn/cid_json.pl hzn/nl/
                cp hzn/epg_json2xml.pl hzn/nl/
                cp hzn/settings.sh hzn/nl/
                cp hzn/chlist_printer.pl hzn/nl/
                cp hzn/compare_menu.pl hzn/nl/
                sed 's/XX/NL/g;s/YYY/nld/g;s/web-api-pepper.horizon.tv/obo-prod.oesp.ziggogo.tv/g' hzn/url_printer.pl > hzn/nl/url_printer.pl
                cd hzn/nl && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/nl/channels.json ]
                then
                    rm -rf hzn/nl
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1115 HORIZON PL #
            # ##################

            elif grep -q "5" "${TMPDIR}/value"
            then
                mkdir hzn/pl
                chmod 0777 hzn/pl
                echo '{"country":"PL","language":"pl"}' > hzn/pl/init.json
                cp hzn/hzn.sh hzn/pl/
                cp hzn/ch_json2xml.pl hzn/pl/
                cp hzn/cid_json.pl hzn/pl/
                cp hzn/epg_json2xml.pl hzn/pl/
                cp hzn/settings.sh hzn/pl/
                cp hzn/chlist_printer.pl hzn/pl/
                cp hzn/compare_menu.pl hzn/pl/
                sed 's/XX/PL/g;s/YYY/pol/g;s/web-api-pepper.horizon.tv/prod.oesp.upctv.pl/g' hzn/url_printer.pl > hzn/pl/url_printer.pl
                cd hzn/pl && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/pl/channels.json ]
                then
                    rm -rf hzn/pl
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1116 HORIZON IE #
            # ##################

            elif grep -q "6" "${TMPDIR}/value"
            then
                mkdir hzn/ie
                chmod 0777 hzn/ie
                echo '{"country":"IE","language":"en"}' > hzn/ie/init.json
                cp hzn/hzn.sh hzn/ie/
                cp hzn/ch_json2xml.pl hzn/ie/
                cp hzn/cid_json.pl hzn/ie/
                cp hzn/epg_json2xml.pl hzn/ie/
                cp hzn/settings.sh hzn/ie/
                cp hzn/chlist_printer.pl hzn/ie/
                cp hzn/compare_menu.pl hzn/ie/
                sed 's/XX/IE/g;s/YYY/eng/g;s/web-api-pepper.horizon.tv/prod.oesp.virginmediatv.ie/g' hzn/url_printer.pl > hzn/ie/url_printer.pl
                cd hzn/ie && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ie/channels.json ]
                then
                    rm -rf hzn/ie
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1117 HORIZON SK #
            # ##################

            elif grep -q "7" "${TMPDIR}/value"
            then
                mkdir hzn/sk
                chmod 0777 hzn/sk
                echo '{"country":"SK","language":"sk"}' > hzn/sk/init.json
                cp hzn/hzn.sh hzn/sk/
                cp hzn/ch_json2xml.pl hzn/sk/
                cp hzn/cid_json.pl hzn/sk/
                cp hzn/epg_json2xml.pl hzn/sk/
                cp hzn/settings.sh hzn/sk/
                cp hzn/chlist_printer.pl hzn/sk/
                cp hzn/compare_menu.pl hzn/sk/
                sed 's/XX/SK/g;s/YYY/slk/g' hzn/url_printer.pl > hzn/sk/url_printer.pl
                cd hzn/sk && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/sk/channels.json ]
                then
                    rm -rf hzn/sk
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1118 HORIZON CZ #
            # ##################

            elif grep -q "8" "${TMPDIR}/value"
            then
                mkdir hzn/cz
                chmod 0777 hzn/cz
                echo '{"country":"CZ","language":"cs"}' > hzn/cz/init.json
                cp hzn/hzn.sh hzn/cz/
                cp hzn/ch_json2xml.pl hzn/cz/
                cp hzn/cid_json.pl hzn/cz/
                cp hzn/epg_json2xml.pl hzn/cz/
                cp hzn/settings.sh hzn/cz/
                cp hzn/chlist_printer.pl hzn/cz/
                cp hzn/compare_menu.pl hzn/cz/
                sed 's/XX/CZ/g;s/YYY/ces/g' hzn/url_printer.pl > hzn/cz/url_printer.pl
                cd hzn/cz && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/cz/channels.json ]
                then
                    rm -rf hzn/cz
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1119 HORIZON HU #
            # ##################

            elif grep -q "9" "${TMPDIR}/value"
            then
                mkdir hzn/hu
                chmod 0777 hzn/hu
                echo '{"country":"HU","language":"hu"}' > hzn/hu/init.json
                cp hzn/hzn.sh hzn/hu/
                cp hzn/ch_json2xml.pl hzn/hu/
                cp hzn/cid_json.pl hzn/hu/
                cp hzn/epg_json2xml.pl hzn/hu/
                cp hzn/settings.sh hzn/hu/
                cp hzn/chlist_printer.pl hzn/hu/
                cp hzn/compare_menu.pl hzn/hu/
                sed 's/XX/HU/g;s/YYY/hun/g' hzn/url_printer.pl > hzn/hu/url_printer.pl
                cd hzn/hu && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/hu/channels.json ]
                then
                    rm -rf hzn/hu
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M111R HORIZON RO #
            # ##################

            elif grep -q "0" "${TMPDIR}/value"
            then
                mkdir hzn/ro
                chmod 0777 hzn/ro
                echo '{"country":"RO","language":"ro"}' > hzn/ro/init.json
                cp hzn/hzn.sh hzn/ro/
                cp hzn/ch_json2xml.pl hzn/ro/
                cp hzn/cid_json.pl hzn/ro/
                cp hzn/epg_json2xml.pl hzn/ro/
                cp hzn/settings.sh hzn/ro/
                cp hzn/chlist_printer.pl hzn/ro/
                cp hzn/compare_menu.pl hzn/ro/
                sed 's/XX/RO/g;s/YYY/ron/g' hzn/url_printer.pl > hzn/ro/url_printer.pl
                cd hzn/ro && bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ro/channels.json ]
                then
                    rm -rf hzn/ro
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M111X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ###############
        # M1120 ZATTOO  #
        # ###############

        elif grep -q "002" "${TMPDIR}/value"
        then
            # M1120 MENU OVERLAY
            echo 'dialog --backtitle "[M1120] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > ZATTOO" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1121 GERMANY
            if [ ! -d ztt/de ]
            then
                echo '	1 "[DE] Zattoo Germany" \' >> "${TMPDIR}/menu"
            fi

            # M1122 SWITZERLAND
            if [ ! -d ztt/ch ]
            then
                echo '	2 "[CH] Zattoo Switzerland" \' >> "${TMPDIR}/menu"
            fi

            # M112E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M112E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > ZATTOO" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ##################
            # M1121 ZATTOO DE  #
            # ##################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir ztt/de
                chmod 0777 ztt/de
                echo '{"country":"DE","language":"de"}' > ztt/de/init.json
                sed 's/\[XX\]/[DE]/g;s/XXXX/DE/g' ztt/settings.sh > ztt/de/settings.sh
                cp ztt/ztt.sh ztt/de/ztt.sh
                cp ztt/compare_crid.pl ztt/de/
                cp ztt/save_page.js ztt/de/
                cp ztt/epg_json2xml.pl ztt/de/
                cp ztt/ch_json2xml.pl ztt/de/
                cp ztt/cid_json.pl ztt/de/
                cp ztt/chlist_printer.pl ztt/de/
                cp ztt/compare_menu.pl ztt/de/
                cd ztt/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e ztt/de/channels.json ]
                then
                    rm -rf ztt/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1122 ZATTOO CH  #
            # ##################

            elif grep -q "2" "${TMPDIR}/value"
            then
                mkdir ztt/ch
                chmod 0777 ztt/ch
                echo '{"country":"CH","language":"de"}' > ztt/ch/init.json
                sed 's/\[XX\]/[CH]/g;s/XXXX/CH/g' ztt/settings.sh > ztt/ch/settings.sh
                cp ztt/ztt.sh ztt/ch/ztt.sh
                cp ztt/compare_crid.pl ztt/ch/
                cp ztt/save_page.js ztt/ch/
                cp ztt/epg_json2xml.pl ztt/ch/
                cp ztt/ch_json2xml.pl ztt/ch/
                cp ztt/cid_json.pl ztt/ch
                cp ztt/chlist_printer.pl ztt/ch/
                cp ztt/compare_menu.pl ztt/ch/
                cd ztt/ch && bash settings.sh
                cd - > /dev/null

                if [ ! -e ztt/ch/channels.json ]
                then
                    rm -rf ztt/ch
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M112X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1130 SWISSCOM  #
        # #################

        elif grep -q "003" "${TMPDIR}/value"
        then
            # M1130 MENU OVERLAY
            echo 'dialog --backtitle "[M1130] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > SWISSCOM" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1131 SWITZERLAND
            if [ ! -d swc/ch ]
            then
                echo '	1 "[CH] SWISSCOM" \' >> "${TMPDIR}/menu"
            fi

            # M113E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M113E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > SWISSCOM" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ####################
            # M1131 SWISSCOM CH  #
            # ####################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir swc/ch
                chmod 0777 swc/ch
                echo '{"country":"CH","language":"de"}' > swc/ch/init.json
                cp swc/settings.sh swc/ch/settings.sh
                cp swc/swc.sh swc/ch/swc.sh
                cp swc/epg_json2xml.pl swc/ch/
                cp swc/ch_json2xml.pl swc/ch/
                cp swc/cid_json.pl swc/ch/
                cp swc/chlist_printer.pl swc/ch/
                cp swc/compare_menu.pl swc/ch/
                cp swc/url_printer.pl swc/ch/
                cd swc/ch && bash settings.sh
                cd - > /dev/null

                if [ ! -e swc/ch/channels.json ]
                then
                    rm -rf swc/ch
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M113X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1140 TVPLAYER  #
        # #################

        elif grep -q "004"  "${TMPDIR}/value"
        then
            # M1140 MENU OVERLAY
            echo 'dialog --backtitle "[M1140] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TVPLAYER" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1141 UK
            if [ ! -d tvp/uk ]
            then
                echo '	1 "[UK] TVPLAYER" \' >> "${TMPDIR}/menu"
            fi

            # M114E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M114E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TVPLAYER" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ####################
            # M1141 TVPLAYER UK  #
            # ####################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir tvp/uk
                chmod 0777 tvp/uk
                echo '{"country":"UK","language":"en"}' > tvp/uk/init.json
                cp tvp/settings.sh tvp/uk/settings.sh
                cp tvp/tvp.sh tvp/uk/tvp.sh
                cp tvp/epg_json2xml.pl tvp/uk/
                cp tvp/ch_json2xml.pl tvp/uk/
                cp tvp/cid_json.pl tvp/uk/
                cp tvp/chlist_printer.pl tvp/uk/
                cp tvp/compare_menu.pl tvp/uk/
                cd tvp/uk && bash settings.sh
                cd - > /dev/null

                if [ ! -e tvp/uk/channels.json ]
                then
                    rm -rf tvp/uk
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M114X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1150 TELEKOM   #
        # #################

        elif grep -q "005"  "${TMPDIR}/value"
        then
            # M1150 MENU OVERLAY
            echo 'dialog --backtitle "[M1150] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TELEKOM" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1151 DE
            if [ ! -d tkm/de ]
            then
                echo '	1 "[DE] MAGENTA TV" \' >> "${TMPDIR}/menu"
            fi

            # M115E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M115E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TELEKOM" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #####################
            # M1151 MAGENTA TV DE #
            # #####################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir tkm/de
                chmod 0777 tkm/de
                echo '{"country":"DE","language":"de"}' > tkm/de/init.json
                cp tkm/settings.sh tkm/de/settings.sh
                cp tkm/tkm.sh tkm/de/tkm.sh
                cp tkm/epg_json2xml.pl tkm/de/
                cp tkm/ch_json2xml.pl tkm/de/
                cp tkm/cid_json.pl tkm/de/
                cp tkm/chlist_printer.pl tkm/de/
                cp tkm/compare_menu.pl tkm/de/
                cp tkm/url_printer.pl tkm/de/
                cp tkm/web_magentatv_de.php tkm/de/
                cp tkm/proxy.sh tkm/de/
                cd tkm/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e tkm/de/channels.json ]
                then
                    rm -rf tkm/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M115X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ##################
        # M1160 RADIOTIMES #
        # ##################

        elif grep -q "006"  "${TMPDIR}/value"
        then
            # M1160 MENU OVERLAY
            echo 'dialog --backtitle "[M1160] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > RADIOTIMES" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1161 DE
            if [ ! -d rdt/uk ]
            then
                echo '	1 "[UK] RADIOTIMES" \' >> "${TMPDIR}/menu"
            fi

            # M116E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M116E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > RADIOTIMES" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #####################
            # M1161 RADIOTIMES UK #
            # #####################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir rdt/uk
                chmod 0777 rdt/uk
                echo '{"country":"UK","language":"en"}' > rdt/uk/init.json
                cp rdt/settings.sh rdt/uk/settings.sh
                cp rdt/rdt.sh rdt/uk/rdt.sh
                cp rdt/epg_json2xml.pl rdt/uk/
                cp rdt/ch_json2xml.pl rdt/uk/
                cp rdt/cid_json.pl rdt/uk/
                cp rdt/chlist_printer.pl rdt/uk/
                cp rdt/compare_menu.pl rdt/uk/
                cp rdt/compare_crid.pl rdt/uk/
                cp rdt/url_printer.pl rdt/uk/
                cd rdt/uk && bash settings.sh
                cd - > /dev/null

                if [ ! -e rdt/uk/channels.json ]
                then
                    rm -rf rdt/uk
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M116X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ##################
        # M1170 WAIPU.TV   #
        # ##################

        elif grep -q "007"  "${TMPDIR}/value"
        then
            # M1170 MENU OVERLAY
            echo 'dialog --backtitle "[M1170] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > WAIPU.TV" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1171 DE
            if [ ! -d wpu/de ]
            then
                echo '	1 "[DE] WAIPU.TV" \' >> "${TMPDIR}/menu"
            fi

            # M117E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M117E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > WAIPU.TV" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #####################
            # M1171 WAIPU.TV DE   #
            # #####################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir wpu/de
                chmod 0777 wpu/de
                echo '{"country":"DE","language":"de"}' > wpu/de/init.json
                cp wpu/settings.sh wpu/de/settings.sh
                cp wpu/wpu.sh wpu/de/wpu.sh
                cp wpu/epg_json2xml.pl wpu/de/
                cp wpu/ch_json2xml.pl wpu/de/
                cp wpu/cid_json.pl wpu/de/
                cp wpu/chlist_printer.pl wpu/de/
                cp wpu/compare_menu.pl wpu/de/
                cd wpu/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e wpu/de/channels.json ]
                then
                    rm -rf wpu/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M117X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ####################
        # M1180 TV-SPIELFILM #
        # ####################

        elif grep -q "008"  "${TMPDIR}/value"
        then
            # M1180 MENU OVERLAY
            echo 'dialog --backtitle "[M1150] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TV-SPIELFILM" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1181 DE
            if [ ! -d tvs/de ]
            then
                echo '	1 "[DE] TV-SPIELFILM" \' >> "${TMPDIR}/menu"
            fi

            # M118E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M115E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TV-SPIELFILM" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #######################
            # M1181 TV-SPIELFILM DE #
            # #######################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir tvs/de
                chmod 0777 tvs/de
                echo '{"country":"DE","language":"de"}' > tvs/de/init.json
                cp tvs/settings.sh tvs/de/settings.sh
                cp tvs/tvs.sh tvs/de/tvs.sh
                cp tvs/epg_json2xml.pl tvs/de/
                cp tvs/ch_json2xml.pl tvs/de/
                cp tvs/cid_json.pl tvs/de/
                cp tvs/chlist_printer.pl tvs/de/
                cp tvs/compare_menu.pl tvs/de/
                cp tvs/url_printer.pl tvs/de/
                cd tvs/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e tvs/de/channels.json ]
                then
                    rm -rf tvs/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M118X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1190 VODAFONE  #
        # #################

        elif grep -q "009"  "${TMPDIR}/value"
        then
            # M1180 MENU OVERLAY
            echo 'dialog --backtitle "[M1150] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > VODAFONE" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1191 DE
            if [ ! -d vdf/de ]
            then
                echo '	1 "[DE] VODAFONE" \' >> "${TMPDIR}/menu"
            fi

            # M119E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M115E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > VODAFONE" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #######################
            # M1191 VODAFONE DE     #
            # #######################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir vdf/de
                chmod 0777 vdf/de
                echo '{"country":"DE","language":"de"}' > vdf/de/init.json
                cp vdf/settings.sh vdf/de/settings.sh
                cp vdf/vdf.sh vdf/de/vdf.sh
                cp vdf/epg_json2xml.pl vdf/de/
                cp vdf/ch_json2xml.pl vdf/de/
                cp vdf/compare_crid.pl vdf/de
                cp vdf/cid_json.pl vdf/de/
                cp vdf/chlist_printer.pl vdf/de/
                cp vdf/compare_menu.pl vdf/de/
                cp vdf/url_printer.pl vdf/de/
                cd vdf/de && bash settings.sh
                cd - > /dev/null

                if [ ! -e vdf/de/channels.json ]
                then
                    rm -rf vdf/de
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M119X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ###############
        # M11A0 TVTV    #
        # ###############

        elif grep -q "010"  "${TMPDIR}/value"
        then
            # M11A0 MENU OVERLAY
            echo 'dialog --backtitle "[M11A0] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TVTV" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M11A1 USA
            if [ ! -d tvtv/us ]
            then
                echo '	1 "[US] TVTV USA" \' >> "${TMPDIR}/menu"
            fi

            # M11A2 CANADA
            if [ ! -d tvtv/ca ]
            then
                echo '	2 "[CA] TVTV CANADA" \' >> "${TMPDIR}/menu"
            fi

            # M11AE ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M11AE] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > TVTV" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi

            ###################
            # M11A1 USA       #
            ###################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir tvtv/us
                chmod 0777 tvtv/us
                echo '{"country":"USA","language":"en"}' > tvtv/us/init.json
                sed 's/XXX/us/g;s/ZZZ/2381D/g;s/YYY/USA/g;s/XYZ/USA/g' tvtv/tvtv.sh > tvtv/us/tvtv.sh
                sed 's/XXX/us/g;s/ZZZ/2381D/g;s/YYY/USA/g;s/XYZ/USA/g' tvtv/ch_json2xml.pl > tvtv/us/ch_json2xml.pl
                cp tvtv/compare_crid.pl tvtv/us/
                cp tvtv/cid_json.pl tvtv/us/
                sed 's/XXX/us/g;s/ZZZ/2381D/g;s/YYY/USA/g;s/XYZ/USA/g' tvtv/epg_json2xml.pl > tvtv/us/epg_json2xml.pl
                sed 's/XXX/us/g;s/ZZZ/2381D/g;s/YYY/USA/g;s/XYZ/USA/g' tvtv/settings.sh > tvtv/us/settings.sh
                cp tvtv/chlist_printer.pl tvtv/us/
                cp tvtv/compare_menu.pl tvtv/us/
                sed 's/XXX/us/g;s/ZZZ/2381D/g;s/YYY/USA/g;s/XYZ/USA/g' tvtv/url_printer.pl > tvtv/us/url_printer.pl
                cd tvtv/us && bash settings.sh
                cd - > /dev/null

                if [ ! -e tvtv/us/channels.json ]
                then
                    rm -rf tvtv/us/
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M11A2 CANADA     #
            # ##################

            elif grep -q "2" "${TMPDIR}/value"
            then
                mkdir tvtv/ca
                chmod 0777 tvtv/ca
                echo '{"country":"CA","language":"en"}' > tvtv/ca/init.json
                sed 's/XXX/ca/g;s/ZZZ/1743/g;s/YYY/CANADA/g;s/XYZ/CN/g' tvtv/tvtv.sh > tvtv/ca/tvtv.sh
                sed 's/XXX/ca/g;s/ZZZ/1743/g;s/YYY/CANADA/g;s/XYZ/CN/g' tvtv/ch_json2xml.pl > tvtv/ca/ch_json2xml.pl
                cp tvtv/compare_crid.pl tvtv/ca/
                cp tvtv/cid_json.pl tvtv/ca/
                sed 's/XXX/ca/g;s/ZZZ/1743/g;s/YYY/CANADA/g;s/XYZ/CN/g' tvtv/epg_json2xml.pl > tvtv/ca/epg_json2xml.pl
                sed 's/XXX/ca/g;s/ZZZ/1743/g;s/YYY/CANADA/g;s/XYZ/CN/g' tvtv/settings.sh > tvtv/ca/settings.sh
                cp tvtv/chlist_printer.pl tvtv/ca/
                cp tvtv/compare_menu.pl tvtv/ca/
                sed 's/XXX/ca/g;s/ZZZ/1743/g;s/YYY/CANADA/g;s/XYZ/CN/g' tvtv/url_printer.pl > tvtv/ca/url_printer.pl
                cd tvtv/ca && bash settings.sh
                cd - > /dev/null

                if [ ! -e tvtv/ca/channels.json ]
                then
                    rm -rf tvtv/ca/
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M11AX EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M11+0 EXTERNAL  #
        # #################

        elif grep -q "+" "${TMPDIR}/value"
        then
            # M11+0 MENU OVERLAY
            echo 'dialog --backtitle "[M11+0] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > EXTERNAL" --title "SERVICE" --menu "Please select the service you want to grab:" 11 50 10 \' > "${TMPDIR}/menu"

            # M11+1 SLOT 1
            if [ ! -d ext/oa ]
            then
                echo '	1 "[OA] EXTERNAL SLOT 1" \' >> "${TMPDIR}/menu"
            fi

            # M11+2 SLOT 2
            if [ ! -d ext/ob ]
            then
                echo '	2 "[OB] EXTERNAL SLOT 2" \' >> "${TMPDIR}/menu"
            fi

            # M11+3 SLOT 3
            if [ ! -d ext/oc ]
            then
                echo '	1 "[OC] EXTERNAL SLOT 3" \' >> "${TMPDIR}/menu"
            fi

            # M11+E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M11+E] EASYEPG SIMPLE XMLTV GRABBER > ADD GRABBER > EXTERNAL" --title "ERROR" --infobox "All services already exist! Please modify them in settings!" 3 65
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # #######################
            # M11+1 EXTERNAL SLOT 1 #
            # #######################

            if grep -q "1" "${TMPDIR}/value"
            then
                mkdir ext/oa
                chmod 0777 ext/oa
                cp ext/settings.sh ext/oa/settings.sh
                cp ext/ext.sh ext/oa/ext.sh
                cp ext/epg_ext.pl ext/oa/
                cp ext/ch_ext.pl ext/oa/
                cp ext/compare_menu.pl ext/oa/
                cd ext/oa && bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/oa/channels.json ]
                then
                    rm -rf ext/oa
                fi

                echo "M" > "${TMPDIR}/value"


            # #######################
            # M11+2 EXTERNAL SLOT 2 #
            # #######################

            elif grep -q "2" "${TMPDIR}/value"
            then
                mkdir ext/ob
                chmod 0777 ext/ob
                cp ext/settings.sh ext/ob/settings.sh
                cp ext/ext.sh ext/ob/ext.sh
                cp ext/epg_ext.pl ext/ob/
                cp ext/ch_ext.pl ext/ob/
                cp ext/compare_menu.pl ext/ob/
                cd ext/ob && bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/ob/channels.json ]
                then
                    rm -rf ext/ob
                fi

                echo "M" > "${TMPDIR}/value"


            # #######################
            # M11+3 EXTERNAL SLOT 3 #
            # #######################

            elif grep -q "3" "${TMPDIR}/value"
            then
                mkdir ext/oc
                chmod 0777 ext/oc
                cp ext/settings.sh ext/oc/settings.sh
                cp ext/ext.sh ext/oc/ext.sh
                cp ext/epg_ext.pl ext/oc/
                cp ext/ch_ext.pl ext/oc/
                cp ext/compare_menu.pl ext/oc/
                cd ext/oc && bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/oc/channels.json ]
                then
                    rm -rf ext/oc
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M11+X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ############
        # M1X00 EXIT #
        # ############

        else
            echo "M" > "${TMPDIR}/value"
        fi


    # #############################
    # M1200 OPEN GRABBER SETTINGS #
    # #############################

    elif grep -q "2" "${TMPDIR}/value"
    then
        # M1200 MENU OVERLAY
        echo 'dialog --backtitle "[M1200] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS" --title "PROVIDERS" --menu "Please select a provider you want to change:" 16 40 10 \' > "${TMPDIR}/menu"

        # M1210 HORIZON
        if ls -l hzn/ | grep -q '^d' 2> /dev/null
        then
            echo '	001 "HORIZON" \' >> "${TMPDIR}/menu"
        fi

        # M1220 ZATTOO
        if ls -l ztt/ | grep -q '^d' 2> /dev/null
        then
            echo '	002 "ZATTOO" \' >> "${TMPDIR}/menu"
        fi

        # M1230 SWISSCOM
        if ls -l swc/ | grep -q '^d' 2> /dev/null
        then
            echo '	003 "SWISSCOM" \' >> "${TMPDIR}/menu"
        fi

        # M1240 TVPLAYER
        if ls -l tvp/ | grep -q '^d' 2> /dev/null
        then
            echo '	004 "TVPLAYER" \' >> "${TMPDIR}/menu"
        fi

        # M1250 TELEKOM
        if ls -l tkm/ | grep -q '^d' 2> /dev/null
        then
            echo '	005 "TELEKOM" \' >> "${TMPDIR}/menu"
        fi

        # M1260 RADIOTIMES
        if ls -l rdt/ | grep -q '^d' 2> /dev/null
        then
            echo '	006 "RADIOTIMES" \' >> "${TMPDIR}/menu"
        fi

        # M1270 WAIPU.TV
        if ls -l wpu/ | grep -q '^d' 2> /dev/null
        then
            echo '	007 "WAIPU.TV" \' >> "${TMPDIR}/menu"
        fi

        # M1280 TV-SPIELFILM
        if ls -l tvs/ | grep -q '^d' 2> /dev/null
        then
            echo '	008 "TV-SPIELFILM" \' >> "${TMPDIR}/menu"
        fi

        # M1290 VODAFONE
        if ls -l vdf/ | grep -q '^d' 2> /dev/null
        then
            echo '	009 "VODAFONE" \' >> "${TMPDIR}/menu"
        fi

        # M12A0 TVTV
        if ls -l tvtv/ | grep -q '^d' 2> /dev/null
        then
            echo '	010 "TVTV" \' >> "${TMPDIR}/menu"
        fi

        # M12+0 EXTERNAL
        if ls -l ext/ | grep -q '^d' 2> /dev/null
        then
            echo '	+ "EXTERNAL" \' >> "${TMPDIR}/menu"
        fi

        echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

        bash "${TMPDIR}/menu"
        input="$(cat "${TMPDIR}/value")"


        # ###############
        # M1210 HORIZON #
        # ###############

        if grep -q "001" "${TMPDIR}/value"
        then
            # M1210 MENU OVERLAY
            echo 'dialog --backtitle "[M1210] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > HORIZON" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1211 GERMANY
            if [ -d hzn/de ]
            then
                echo '	1 "[DE] Unitymedia Germany" \' >> "${TMPDIR}/menu"
            fi

            # M1212 AUSTRIA
            if [ -d hzn/at ]
            then
                echo '	2 "[AT] Magenta T" \' >> "${TMPDIR}/menu"
            fi

            # M1213 SWITZERLAND
            if [ -d hzn/ch ]
            then
                echo '	3 "[CH] UPC Switzerland" \' >> "${TMPDIR}/menu"
            fi

            # M1214 NETHERLANDS
            if [ -d hzn/nl ]
            then
                echo '	4 "[NL] Ziggo Netherlands" \' >> "${TMPDIR}/menu"
            fi

            # M1215 POLAND
            if [ -d hzn/pl ]
            then
                echo '	5 "[PL] Horizon Poland" \' >> "${TMPDIR}/menu"
            fi

            # M1216 IRELAND
            if [ -d hzn/ie ]
            then
                echo '	6 "[IE] Virgin Media Ireland" \' >> "${TMPDIR}/menu"
            fi

            # M1217 SLOVAKIA
            if [ -d hzn/sk ]
            then
                echo '	7 "[SK] Horizon Slovakia" \' >> "${TMPDIR}/menu"
            fi

            # M1218 CZECH REPUBLIC
            if [ -d hzn/cz ]
            then
                echo '	8 "[CZ] Horizon Czech Republic" \' >> "${TMPDIR}/menu"
            fi

            # M1219 HUNGARY
            if [ -d hzn/hu ]
            then
                echo '	9 "[HU] Horizon Hungary" \' >> "${TMPDIR}/menu"
            fi

            # M121R ROMANIA
            if [ -d hzn/ro ]
            then
                echo '	0 "[RO] Horizon Romania" \' >> "${TMPDIR}/menu"
            fi

            # M121E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M121E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > HORIZON" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ##################
            # M1211 HORIZON DE #
            # ##################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd hzn/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/de/channels.json ]
                then
                    rm -rf hzn/de xml/horizon_de.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1212 HORIZON AT #
            # ##################

            elif grep -q "2" "${TMPDIR}/value"
            then
                cd hzn/at
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/at/channels.json ]
                then
                    rm -rf hzn/at xml/horizon_at.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1213 HORIZON CH #
            # ##################

            elif grep -q "3" "${TMPDIR}/value"
            then
                cd hzn/ch
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ch/channels.json ]
                then
                    rm -rf hzn/ch xml/horizon_ch.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1214 HORIZON NL #
            # ##################

            elif grep -q "4" "${TMPDIR}/value"
            then
                cd hzn/nl
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/nl/channels.json ]
                then
                    rm -rf hzn/nl xml/horizon_nl.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1215 HORIZON PL #
            # ##################

            elif grep -q "5" "${TMPDIR}/value"
            then
                cd hzn/pl
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/pl/channels.json ]
                then
                    rm -rf hzn/pl xml/horizon_pl.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1216 HORIZON IE #
            # ##################

            elif grep -q "6" "${TMPDIR}/value"
            then
                cd hzn/ie
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ie/channels.json ]
                then
                    rm -rf hzn/ie xml/horizon_ie.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1217 HORIZON SK #
            # ##################

            elif grep -q "7" "${TMPDIR}/value"
            then
                cd hzn/sk
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/sk/channels.json ]
                then
                    rm -rf hzn/sk xml/horizon_sk.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1218 HORIZON CZ #
            # ##################

            elif grep -q "8" "${TMPDIR}/value"
            then
                cd hzn/cz
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/cz/channels.json ]
                then
                    rm -rf hzn/cz xml/horizon_cz.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1219 HORIZON HU #
            # ##################

            elif grep -q "9" "${TMPDIR}/value"
            then
                cd hzn/hu
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/hu/channels.json ]
                then
                    rm -rf hzn/hu xml/horizon_hu.xml
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M121R HORIZON RO #
            # ##################

            elif grep -q "0" "${TMPDIR}/value"
            then
                cd hzn/ro
                bash settings.sh
                cd - > /dev/null

                if [ ! -e hzn/ro/channels.json ]
                then
                    rm -rf hzn/ro xml/horizon_ro.xml
                fi

                echo "M" > "${TMPDIR}/value"

            # ############
            # M121X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ###############
        # M1220 ZATTOO  #
        # ###############

        elif grep -q "002" "${TMPDIR}/value"
        then
            # M1220 MENU OVERLAY
            echo 'dialog --backtitle "[M1220] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > ZATTOO" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1221 GERMANY
            if [ -d ztt/de ]
            then
                echo '	1 "[DE] Zattoo Germany" \' >> "${TMPDIR}/menu"
            fi

            # M1222 SWITZERLAND
            if [ -d ztt/ch ]
            then
                echo '	2 "[CH] Zattoo Switzerland" \' >> "${TMPDIR}/menu"
            fi

            # M122E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M122E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > ZATTOO" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ##################
            # M1221 ZATTOO DE  #
            # ##################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd ztt/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e ztt/de/channels.json ]
                then
                    rm -rf ztt/de xml/zattoo_de.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ##################
            # M1222 ZATTOO CH  #
            # ##################

            elif grep -q "2" "${TMPDIR}/value"
            then
                cd ztt/ch
                bash settings.sh
                cd - > /dev/null

                if [ ! -e ztt/ch/channels.json ]
                then
                    rm -rf ztt/ch xml/zattoo_ch.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M122X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1230 SWISSCOM  #
        # #################

        elif grep -q "003" "${TMPDIR}/value"
        then
            # M1230 MENU OVERLAY
            echo 'dialog --backtitle "[M1230] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > SWISSCOM" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1231 SWISSCOM CH
            if [ -d swc/ch ]
            then
                echo '	1 "[CH] SWISSCOM" \' >> "${TMPDIR}/menu"
            fi

            # M123E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M123E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > SWISSCOM" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ####################
            # M1231 SWISSCOM CH  #
            # ####################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd swc/ch
                bash settings.sh
                cd - > /dev/null

                if [ ! -e swc/ch/channels.json ]
                then
                    rm -rf swc/ch xml/swisscom_ch.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M123X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # #################
        # M1240 TVPLAYER  #
        # #################

        elif grep -q "004" "${TMPDIR}/value"
        then
            # M1240 MENU OVERLAY
            echo 'dialog --backtitle "[M1240] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TVPLAYER" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1241 TVPLAYER UK
            if [ -d tvp/uk ]
            then
                echo '	1 "[UK] TVPLAYER" \' >> "${TMPDIR}/menu"
            fi

            # M124E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M124E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TVPLAYER" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ####################
            # M1241 TVPLAYER UK  #
            # ####################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd tvp/uk
                bash settings.sh
                cd - > /dev/null

                if [ ! -e tvp/uk/channels.json ]
                then
                    rm -rf tvp/uk xml/tvplayer_uk.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M124X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ######################
        # M1250 MAGENTA TV DE  #
        # ######################

        elif grep -q "005" "${TMPDIR}/value"
        then
            # M1250 MENU OVERLAY
            echo 'dialog --backtitle "[M1250] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TELEKOM" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1251 MAGENTA TV DE
            if [ -d tkm/de ]
            then
                echo '	1 "[DE] MAGENTATV" \' >> "${TMPDIR}/menu"
            fi

            # M125E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M125E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TELEKOM" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ######################
            # M1251 MAGENTA TV DE  #
            # ######################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd tkm/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e tkm/de/channels.json ]
                then
                    rm -rf tkm/de xml/magentatv_de.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M125X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ##################
        # M1260 RADIOTIMES #
        # ##################

        elif grep -q "006" "${TMPDIR}/value"
        then
            # M1260 MENU OVERLAY
            echo 'dialog --backtitle "[M1260] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > RADIOTIMES" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1261 RADIOTIMES UK
            if [ -d rdt/uk ]
            then
                echo '	1 "[UK] RADIOTIMES" \' >> "${TMPDIR}/menu"
            fi

            # M126E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M126E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > RADIOTIMES" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ######################
            # M1261 RADIOTIMES UK  #
            # ######################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd rdt/uk
                bash settings.sh
                cd - > /dev/null

                if [ ! -e rdt/uk/channels.json ]
                then
                    rm -rf rdt/uk xml/radiotimes_uk.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M126X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ##################
        # M1270 WAIPU.TV   #
        # ##################

        elif grep -q "007" "${TMPDIR}/value"
        then
            # M1270 MENU OVERLAY
            echo 'dialog --backtitle "[M1270] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > WAIPU.TV" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1271 WAIPU.TV DE
            if [ -d wpu/de ]
            then
                echo '	1 "[DE] WAIPU.TV" \' >> "${TMPDIR}/menu"
            fi

            # M127E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M127E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > WAIPU.TV" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ######################
            # M1271 WAIPU.TV DE    #
            # ######################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd wpu/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e wpu/de/channels.json ]
                then
                    rm -rf wpu/de xml/waipu_de.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M127X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi

        # ######################
        # M1280 TV-SPIELFILM   #
        # ######################

        elif grep -q "008" "${TMPDIR}/value"
        then
            # M1280 MENU OVERLAY
            echo 'dialog --backtitle "[M1280] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TV-SPIELFILM" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1281 TV-SPIELFILM  DE
            if [ -d tvs/de ]
            then
                echo '	1 "[DE] TV-SPIELFILM " \' >> "${TMPDIR}/menu"
            fi

            # M128E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M128E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TV-SPIELFILM " --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ######################
            # M1281 TV-SPIELFILM   #
            # ######################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd tvs/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e tvs/de/channels.json ]
                then
                    rm -rf tvs/de xml/tv-spielfilm_de.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M128X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi

        # ######################
        # M1290 VODAFONE   #
        # ######################

        elif grep -q "009" "${TMPDIR}/value"
        then
            # M1290 MENU OVERLAY
            echo 'dialog --backtitle "[M1290] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > VODAFONE" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M1291 VODAFONE  DE
            if [ -d vdf/de ]
            then
                echo '	1 "[DE] VODAFONE " \' >> "${TMPDIR}/menu"
            fi

            # M128E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M129E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > VODAFONE " --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ######################
            # M1291 VODAFONE       #
            # ######################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd vdf/de
                bash settings.sh
                cd - > /dev/null

                if [ ! -e vdf/de/channels.json ]
                then
                    rm -rf vdf/de xml/vodafone_de.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M129X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ###############
        # M12A0 TVTV    #
        # ###############

        elif grep -q "010" "${TMPDIR}/value"
        then
            # M12A0 MENU OVERLAY
            echo 'dialog --backtitle "[M12A0] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TVTV" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M12A1 USA
            if [ -d tvtv/us ]
            then
                echo '	1 "[US] TVTV USA" \' >> "${TMPDIR}/menu"
            fi

            # M12A2 CANADA
            if [ -d tvtv/ca ]
            then
                echo '	2 "[CA] TVTV CANADA" \' >> "${TMPDIR}/menu"
            fi

            # M12AE ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M12AE] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > TVTV" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ##################
            # M12A1 TVTV US    #
            # ##################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd tvtv/us
                bash settings.sh
                cd - > /dev/null

                if [ ! -e tvtv/us/channels.json ]
                then
                    rm -rf tvtv/us xml/tvtv_us.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ####################
            # M12A2 TVTV CANADA  #
            # ####################

            elif grep -q "2" "${TMPDIR}/value"
            then
                cd tvtv/ca
                bash settings.sh
                cd - > /dev/null

                if [ ! -e tvtv/ca/channels.json ]
                then
                    rm -rf tvtv/ca xml/tvtv_ca.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M12AX EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ######################
        # M12+0 EXTERNAL       #
        # ######################

        elif grep -q "+" "${TMPDIR}/value"
        then
            # M12+0 MENU OVERLAY
            echo 'dialog --backtitle "[M12+0] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > EXTERNAL" --title "SERVICE" --menu "Please select the service you want to change:" 11 50 10 \' > "${TMPDIR}/menu"

            # M12+1 EXTERNAL SLOT 1
            if [ -d ext/oa ]
            then
                echo '	1 "[OA] EXTERNAL SLOT 1" \' >> "${TMPDIR}/menu"
            fi

            # M12+2 EXTERNAL SLOT 2
            if [ -d ext/ob ]
            then
                echo '	2 "[OB] EXTERNAL SLOT 2" \' >> "${TMPDIR}/menu"
            fi

            # M12+3 EXTERNAL SLOT 3
            if [ -d ext/oc ]
            then
                echo '	3 "[OC] EXTERNAL SLOT 3" \' >> "${TMPDIR}/menu"
            fi

            # M12+E ERROR
            if ! grep -q '[0-9] "\[[A-Z][A-Z]\] ' "${TMPDIR}/menu"
            then
                dialog --backtitle "[M12+E] EASYEPG SIMPLE XMLTV GRABBER > SETTINGS > EXTERNAL" --title "ERROR" --infobox "No service available! Please setup a service first!" 3 55
                sleep 2s
                echo "M" > "${TMPDIR}/value"
            else
                echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

                bash "${TMPDIR}/menu"
                input="$(cat "${TMPDIR}/value")"
            fi


            # ########################
            # M12+1 EXTERNAL SLOT 1  #
            # ########################

            if grep -q "1" "${TMPDIR}/value"
            then
                cd ext/oa
                bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/oa/channels.json ]
                then
                    rm -rf ext/oa xml/external_oa.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ########################
            # M12+2 EXTERNAL SLOT 2  #
            # ########################

            elif grep -q "2" "${TMPDIR}/value"
            then
                cd ext/ob
                bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/ob/channels.json ]
                then
                    rm -rf ext/ob xml/external_ob.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ########################
            # M12+3 EXTERNAL SLOT 3  #
            # ########################

            elif grep -q "3" "${TMPDIR}/value"
            then
                cd ext/oc
                bash settings.sh
                cd - > /dev/null

                if [ ! -e ext/oc/channels.json ]
                then
                    rm -rf ext/oc xml/external_oc.xml 2> /dev/null
                fi

                echo "M" > "${TMPDIR}/value"


            # ############
            # M12+X EXIT #
            # ############

            else
                echo "M" > "${TMPDIR}/value"
            fi


        # ############
        # M12X0 EXIT #
        # ############

        else
            echo "M" > "${TMPDIR}/value"
        fi


    # ####################################
    # M1300 CREATE MULTI-SOURCE XML FILE #
    # ####################################

    elif grep -q "3" "${TMPDIR}/value"
    then
        echo "C" > "${TMPDIR}/value"
        while grep -q "C" "${TMPDIR}/value"
        do
            bash combine.sh
        done
        echo "M" > "${TMPDIR}/value"


    # ################################
    # M1400 CONTINUE IN GRABBER MODE #
    # ################################

    elif grep -q "4" "${TMPDIR}/value"
    then
        echo "G" > "${TMPDIR}/value"


    # ##############
    # M1500 UPDATE #
    # ##############

    elif grep -q "5" "${TMPDIR}/value"
    then
        ## TODO: Logig muss überarbeitet werden
        clear

        rm -rf easyepg 2> /dev/null
        git clone https://github.com/sunsettrack4/easyepg

        if [ -e easyepg/update.sh ]
        then
            bash easyepg/update.sh
            rm -rf easyepg 2> /dev/null
            read -n 1 -s -r -p "Press any key to continue..."
            bash epg.sh
            cleanup 0
        else
            rm -rf easyepg 2> /dev/null
            printf "\r[ ERROR ]  Missing script: update.sh\n"
            read -n 1 -s -r -p "Press any key to continue..."
            echo "M" > "${TMPDIR}/value"
        fi


    # ###########################
    # M1600 BACKUP / RESTORE    #
    # ###########################

    elif grep -q "6" "${TMPDIR}/value"
    then
        # M1610 MENU OVERLAY
        echo 'dialog --backtitle "[M1610] EASYEPG SIMPLE XMLTV GRABBER > BACKUP/RESTORE" --title "OPTIONS" --menu "Please select the desired action:" 9 40 10 \' > "${TMPDIR}/menu"

        # M1611 BACKUP
        true > "${TMPDIR}/providerlist"
        for Provider in $PROVIDERLIST; do  ls -l "$Provider/" >> "${TMPDIR}/providerlist" ; done
        if grep -q '^d' "${TMPDIR}/providerlist" 2> /dev/null
        then
            echo '	1 "BACKUP SETUP" \' >> "${TMPDIR}/menu"
        fi

        # M1612 RESTORE
        if [ -e easyepg_backup.zip ]
        then
            echo '	2 "RESTORE SETUP" \' >> "${TMPDIR}/menu"
        fi

        echo "2> ${TMPDIR}/value" >> "${TMPDIR}/menu"

        bash "${TMPDIR}/menu"
        # input="$(cat "${TMPDIR}/value")"


        # ########################
        # M1611 BACKUP SETUP     #
        # ########################

        if grep -q "1" "${TMPDIR}/value"
        then
            clear
            echo ""
            echo " --------------------------------------------"
            echo " BACKUP SERVICE                              "
            echo " easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
            echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
            echo " --------------------------------------------"
            echo ""
            sleep 2s
            bash backup.sh
            read -n 1 -s -r -p "Press any key to continue..."
            echo "M" > "${TMPDIR}/value"


        # ########################
        # M1612 RESTORE SETUP    #
        # ########################

        elif grep -q "2" "${TMPDIR}/value"
        then
            clear
            echo ""
            echo " --------------------------------------------"
            echo " RESTORE SERVICE                             "
            echo " easyEPG Grabber $(grep 'VER=' "${TMPDIR}/initrun.txt" | sed 's/VER=//g')"
            echo " (c) 2019-2020 Jan-Luca Neumann / sunsettrack4    "
            echo " --------------------------------------------"
            echo ""
            sleep 2s
            bash restore.sh
            read -n 1 -s -r -p "Press any key to continue..."
            echo "M" > "${TMPDIR}/value"


        # ############
        # M16X0 EXIT #
        # ############

        else
            echo "M" > "${TMPDIR}/value"
        fi


    # ###########################
    # M1900 ABOUT THIS PROJECT  #
    # ###########################

    elif grep -q "9" "${TMPDIR}/value"
    then
        dialog --backtitle "[M1900] EASYEPG SIMPLE XMLTV GRABBER > ABOUT"  --title "ABOUT THE EASYEPG PROJECT" --msgbox "easyEPG Grabber\n(c) 2019-2020 Jan-Luca Neumann / sunsettrack4\nhttps://github.com/sunsettrack4\n\nLicensed under GPL v3.0 - All rights reserved.\n\n* This tool provides high-quality EPG data from different IPTV/OTT sources.\n* It allows you to combine multiple sources for XMLTV file creation.\n* Missing data can be added by using the IMDB mapper tool.\n* Furthermore, you can import XML files from external sources.\n\nSpecial thanks:\n- DeBaschdi - https://github.com/debaschdi (for collaboration)" 19 70
        echo "M" > "${TMPDIR}/value"

    # ############
    # M1X00 EXIT #
    # ############

    else
        dialog --backtitle "[M1X00] EASYEPG SIMPLE XMLTV GRABBER > EXIT"  --title "EXIT" --yesno "Do you want to quit?" 5 30

        response=$?

        if [ $response = 1 ]
        then
            echo "M" > "${TMPDIR}/value"
        elif [ $response = 0 ]
        then
            cleanup 0
        else
            echo "M" > "${TMPDIR}/value"
        fi
    fi
done


# ##########################
# CONTINUE IN GRABBER MODE #
# ##########################
clear

if grep -q "G" "${TMPDIR}/value" ; then grabber_mode ; fi
combine_xml_files

### EOF ###