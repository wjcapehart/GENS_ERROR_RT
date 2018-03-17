#!/bin/bash

# start and end dates for the long run
LONG_GAME_START_DATE=2016-06-01
LONG_GAME_END_DATE=2018-03-17

# converting these into time in system seconds
CURRENTDATE_TS=`date --date ${LONG_GAME_START_DATE} '+%s'`
ENDDATE_TS=`date --date ${LONG_GAME_END_DATE} '+%s'`


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



while [ "${CURRENTDATE_TS}" -le "${ENDDATE_TS}" ]
do

   # producing the CI brackets for this period
   END_DATE=`date --date=@${CURRENTDATE_TS} "+%Y-%m-%d"`
   CURRENT_STARTDATE_TS=$((${CURRENTDATE_TS}+${OFFSET_CI_TS}))
   START_DATE=`date --date=@$((${CURRENTDATE_TS}+${OFFSET_CI_TS})) "+%Y-%m-%d"`


   for WORKING_HOUR in 00 06 12 18
   do
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


            if [ ${VARIABLE} == "ISOHGT"  ] &&  [ ${LOCATION} == "WRFRAP" ]
            then


               # command-line syntax should read (for example for a fast test case):
               #  ncl 'file_label="ISOHGT"' 'scenario="WRFRAP"' 'start_date_string="2017-03-15"' 'end_date_string="2017-03-17"' 'working_hour="12"' script_plot_triangle_product_ISOHGT.ncl

               echo ncl file_label='"'${VARIABLE}'"' \
                        scenario='"'${LOCATION}'"' \
                        start_date_string='"'${START_DATE}'"'   \
                        end_date_string='"'${END_DATE}'"'       \
                        working_hour='"'${WORKING_HOUR}'"'       \
                        script_plot_triangle_product_ISOHGT_retro.ncl

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


   done





   # moving ahead one day and return
   CURRENTDATE_TS=$((${CURRENTDATE_TS}+${OFFSET_DAILY_TS}))

done
