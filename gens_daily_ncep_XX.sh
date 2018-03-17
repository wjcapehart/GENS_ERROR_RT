#!/bin/bash

CURRENTDATE_TS=`date --utc +%s`

WORKING_HOUR=00

# Offset for Daily Time Step
OFFSET_DAILY_TS=86400

# Offset for CI Time Range
OFFSET_CI_TS=$((-2*${OFFSET_DAILY_TS}))

declare -a VARIABLE_LIST=( ISOHGT
                           MSLP
                           T2M
                           SPCH2M
                           U10
                           V10
                           UFLX
                           VFLX
                           FRICV
                           GUST
                           APCP )

declare -a LOCATION_LIST=( WRFRAP
                           ARMCAR
                           NAMIBI
                           UCONUS )


# Retrieve files from NCEP NOMADS servers with IDL script below
cd /data/NCAR/GENS

/usr/local/bin/idl   << endidl
.run /data/NCAR/GENS/gens_daily_ncep_${WORKING_HOUR}.pro
endidl

# begin post processing of the NCEP GENS data

cd /projects/BIG_WEATHER/GENS_ERROR_RT

   # producing the CI brackets for this period

   END_DATE=`date --utc --date=@${CURRENTDATE_TS} "+%Y-%m-%d"`
   START_DATE=`date  --utc --date=@$((${CURRENTDATE_TS}+${OFFSET_CI_TS})) "+%Y-%m-%d"`

   echo ${START_DATE}_${WORKING_HOUR} to ${END_DATE}_${WORKING_HOUR}

   for LOCATION in "${LOCATION_LIST[@]}"
   do
      echo "====================================================="
      echo "ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ"
      echo

      for VARIABLE in "${VARIABLE_LIST[@]}"
      do
         echo "====================================================="
         echo

         echo $LOCATION $VARIABLE  ${START_DATE}_${WORKING_HOUR}

         echo
         echo "-----------------------------------------------------"
         echo

         # command-line syntax should read (for example for a fast test case):
         #  ncl 'FILE_LABEL="T2M"' 'scenario="WRFRAP"' 'start_date_string="2016-01-01"' 'end_date_string="2016-01-10"'  script_T2M_read_ensembles_from_thredds.ncl

         echo ncl file_label='"'${VARIABLE}'"' \
                  scenario='"'${LOCATION}'"' \
                  start_date_string='"'$START_DATE'"'   \
                  end_date_string='"'${END_DATE}'"'       \
                  working_hour='"'${WORKING_HOUR}'"'       \
                  script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
         echo


         ncl file_label='"'$VARIABLE'"' \
             scenario='"'$LOCATION'"' \
             start_date_string='"'$START_DATE'"'   \
             end_date_string='"'${END_DATE}'"'       \
             working_hour='"'${WORKING_HOUR}'"'       \
             script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "-----------------------------------------------------"
         echo


         if [ ${VARIABLE} == "ISOHGT"  ] && [${LOCATION} == "WRFRAP" ]
         then

            # command-line syntax should read (for example for a fast test case):
            #  ncl 'FILE_LABEL="ISOHGT"' 'scenario="WRFRAP"' 'start_date_string="2017-03-15"' 'end_date_string="2017-03-17"' 'working_hour="12"' script_plot_triangle_product_ISOHGT.ncl

            echo ncl file_label='"'${VARIABLE}'"' \
                     scenario='"'${LOCATION}'"' \
                     start_date_string='"'${START_DATE}'"'   \
                     end_date_string='"'${END_DATE}'"'       \
                     working_hour='"'${WORKING_HOUR}'"'       \
                     script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
            echo

            ncl file_label='"'$VARIABLE'"' \
                scenario='"'$LOCATION'"' \
                start_date_string='"'${START_DATE}'"'   \
                end_date_string='"'${END_DATE}'"'       \
                working_hour='"'${WORKING_HOUR}'"'       \
                script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "-----------------------------------------------------"
            echo

         fi
      done

      echo
      echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
      echo

   done

echo Outahere like Vladimir
