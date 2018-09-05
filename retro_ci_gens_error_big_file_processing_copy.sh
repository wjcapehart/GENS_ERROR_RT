#!/bin/bash
source ~wjc/.bash_profile
# start and end dates for the long run
LONG_GAME_START_DATE=2017-10-29
LONG_GAME_END_DATE=2018-03-17

startdate=(
            "2017-02-01"
            "2017-03-01"
            "2017-04-01"
            "2017-05-01"
            "2017-06-01"
            "2017-07-01"
            "2017-08-01"
            "2017-09-01"
            "2017-10-01"
            "2017-11-01"
            "2017-12-01"
            "2018-01-01"
            "2018-02-01"
            "2018-03-01" )

eomdate=(   "2017-02-28"
            "2017-03-31"
            "2017-04-30"
            "2017-05-31"
            "2017-06-30"
            "2017-07-31"
            "2017-08-31"
            "2017-09-30"
            "2017-10-31"
            "2017-11-30"
            "2017-12-31"
            "2018-01-31"
            "2018-02-28"
            "2018-03-31" )

number_of_months=${#startdate[@]}

echo Number of Months ${number_of_months}


declare -a VARIABLE_LIST=( T2M
                           ISOHGT
                           MSLP
                           SPCH2M
                           U10
                           V10
                           UFLX
                           VFLX
                           FRICV
                           GUST
                           APCP )


declare -a VARIABLE_LIST=( ISOHGT )


declare -a LOCATION_LIST=( WRFRAP
                           ARMCAR
                           NAMIBI
                           UCONUS )

declare -a LOCATION_LIST=( WRFRAP )

                           for LOCATION in "${LOCATION_LIST[@]}"
                           do
                              for VARIABLE in "${VARIABLE_LIST[@]}"
                              do

for (( i=1; i<${number_of_months}+1; i++ ));
do

   # producing the CI brackets for this period
   END_DATE=${eomdate[$i-1]}
   START_DATE=${startdate[$i-1]}


   for WORKING_HOUR in 00
   do
      echo ${START_DATE}_${WORKING_HOUR} to ${END_DATE}_${WORKING_HOUR}

         echo "====================================================="
         echo "ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ"
         echo

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
                     start_date_string='"'${START_DATE}'"'   \
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
                ./script_${VARIABLE}_read_ensembles_from_thredds.ncl

            echo
            echo "-----------------------------------------------------"
            echo

            mv -v error_data/GENS_03_ENSEMBLE__${VARIABLE}__ERROR__${LOCATION}__${START_DATE}_${WORKING_HOUR}_to_${END_DATE}_${WORKING_HOUR}.nc /projects/BIG_WEATHER/GENS_ERROR_RT/triangle_archives


            echo
            echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
            echo

         done

      done

   done





done
