#!/bin/bash

. /home/bash_profile_ias
. /usr/local/exelis/idl85/bin/idl_setup.bash

idl=/usr/local/exelis/idl85/bin/idl
ncl=/usr/local/bin/ncl

which idl


ulimit -f unlimited

declare -a VARIABLE_LIST=( "ISOHGT" "MSLP" "T2M" "SPCH2M" "U10" "V10" "M10" "UFLX" "VFLX" "FRICV" "GUST" "APCP" )

declare -a LOCATION_LIST=( "WRFRAP" "ARMCAR"  "UCONUS" )

HH=06


START_DATE=`date --utc -d "2 day ago" '+%Y-%m-%d'`
END_DATE=`date   --utc -d "0 day ago" '+%Y-%m-%d'`

echo ${START_DATE}
echo ${END_DATE}

cd /data/NCAR/GENS


$idl   << endidl
.run /data/NCAR/GENS/gens_daily_ncep_${HH}.pro
endidl

cd /projects/BIG_WEATHER/GENS_ERROR_RT


for LOCATION in "${LOCATION_LIST[@]}";
do
   echo "====================================================="
   echo "ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ"
   echo

   for VARIABLE in "${VARIABLE_LIST[@]}";
   do

         echo "====================================================="
         echo

         echo ${LOCATION} ${VARIABLE}  ${START_DATE}_${HH}

         echo
         echo "-----------------------------------------------------"
         echo

         # command-line syntax should read (for example for a fast test case):
         #  ncl 'file_label="T2M"' 'scenario="WRFRAP"' 'working_hour="00"'  'start_date_string="2017-06-25"' 'end_date_string="2017-07-05"'  script_T2M_read_ensembles_from_thredds.ncl

         echo ncl file_label='"'${VARIABLE}'"' \
                  scenario='"'${LOCATION}'"' \
                  start_date_string='"'$START_DATE'"'   \
                  end_date_string='"'${END_DATE}'"'       \
                  working_hour='"'$HH'"'       \
                  script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
         echo


         $ncl file_label='"'$VARIABLE'"' \
             scenario='"'$LOCATION'"' \
             start_date_string='"'$START_DATE'"'   \
             end_date_string='"'${END_DATE}'"'       \
             working_hour='"'$HH'"'       \
             script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "-----------------------------------------------------"
         echo


         if [[ ${VARIABLE} == "ISOHGT" ]]   && [[ ${LOCATION} == "WRFRAP" ]]; then


            # command-line syntax should read (for example for a fast test case):
            #  ncl 'file_label="ISOHGT"' 'scenario="WRFRAP"' 'working_hour="00"'  'start_date_string="2017-06-25"' 'end_date_string="2017-07-05"'   script_plot_triangle_product_ISOHGT.ncl

            echo ncl file_label='"'${VARIABLE}'"' \
                     scenario='"'${LOCATION}'"' \
                     start_date_string='"'${START_DATE}'"'   \
                     end_date_string='"'${END_DATE}'"'       \
                     working_hour='"'$HH'"'       \
                     script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
            echo


            $ncl file_label='"'$VARIABLE'"' \
                scenario='"'$LOCATION'"' \
                start_date_string='"'${START_DATE}'"'   \
                end_date_string='"'${END_DATE}'"'       \
                working_hour='"'$HH'"'       \
                script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "-----------------------------------------------------"
            echo


         fi



         if [[ ${VARIABLE} == "MSLP" ]]   && [[ ${LOCATION} == "WRFRAP" ]]; then

            # command-line syntax should read (for example for a fast test case):
            #  ncl 'file_label="MSLP"' 'scenario="WRFRAP"' 'working_hour="00"'  'start_date_string="2017-06-25"' 'end_date_string="2017-07-05"'   script_plot_triangle_product_ISOHGT.ncl

            echo ncl file_label='"'${VARIABLE}'"' \
                     scenario='"'${LOCATION}'"' \
                     start_date_string='"'${START_DATE}'"'   \
                     end_date_string='"'${END_DATE}'"'       \
                     working_hour='"'$HH'"'       \
                     script_plot_triangle_product_MSLP.ncl

            echo
            echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
            echo

            $ncl file_label='"'$VARIABLE'"' \
                scenario='"'$LOCATION'"' \
                start_date_string='"'${START_DATE}'"'   \
                end_date_string='"'${END_DATE}'"'       \
                working_hour='"'$HH'"'       \
                script_plot_triangle_product_MSLP.ncl

            echo
            echo "-----------------------------------------------------"
            echo

         fi




        if [[ ${VARIABLE} == "T2M" ]]  && [[ ${LOCATION} == "WRFRAP" ]]; then

           # command-line syntax should read (for example for a fast test case):
           #  ncl 'file_label="MSLP"' 'scenario="WRFRAP"' 'working_hour="00"'  'start_date_string="2017-06-25"' 'end_date_string="2017-07-05"'   script_plot_triangle_product_ISOHGT.ncl

           echo ncl file_label='"'${VARIABLE}'"' \
                    scenario='"'${LOCATION}'"' \
                    start_date_string='"'${START_DATE}'"'   \
                    end_date_string='"'${END_DATE}'"'       \
                    working_hour='"'$HH'"'       \
                    script_plot_triangle_product_T2M.ncl

           echo
           echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
           echo

           $ncl file_label='"'$VARIABLE'"' \
               scenario='"'$LOCATION'"' \
               start_date_string='"'${START_DATE}'"'   \
               end_date_string='"'${END_DATE}'"'       \
               working_hour='"'$HH'"'       \
               script_plot_triangle_product_T2M.ncl

           echo
           echo "-----------------------------------------------------"
           echo

        fi


        if [[ ${VARIABLE} == "M10" ]]  && [[ ${LOCATION} == "WRFRAP" ]]; then

           # command-line syntax should read (for example for a fast test case):
           #  ncl 'file_label="MSLP"' 'scenario="WRFRAP"' 'working_hour="00"'  'start_date_string="2017-06-25"' 'end_date_string="2017-07-05"'   script_plot_triangle_product_M10.ncl

           echo ncl file_label='"'${VARIABLE}'"' \
                    scenario='"'${LOCATION}'"' \
                    start_date_string='"'${START_DATE}'"'   \
                    end_date_string='"'${END_DATE}'"'       \
                    working_hour='"'$HH'"'       \
                    script_plot_triangle_product_M10.ncl

           echo
           echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
           echo

           $ncl file_label='"'$VARIABLE'"' \
               scenario='"'$LOCATION'"' \
               start_date_string='"'${START_DATE}'"'   \
               end_date_string='"'${END_DATE}'"'       \
               working_hour='"'$HH'"'       \
               script_plot_triangle_product_M10.ncl

           echo
           echo "-----------------------------------------------------"
           echo

        fi


   done





   echo
   echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
   echo


done
