#/bin/tcsh

ulimit -f unlimited

set HH = 06

set START_DATE=`date --utc -d "2 day ago" '+%Y-%m-%d'`
set end_date=`date --utc -d "0 day ago" '+%Y-%m-%d'`

echo ${START_DATE}
echo ${END_DATE}

cd /data/NCAR/GENS


set VARIABLE_LIST = ( ISOHGT MSLP T2M SPCH2M U10 V10 UFLX VFLX FRICV GUST APCP )

set LOCATION_LIST =  (WRFRAP ARMCAR NAMIBI  UCONUS)


/usr/local/bin/idl   << endidl
.run /data/NCAR/GENS/gens_daily_ncep_${HH}.pro
endidl

cd /projects/BIG_WEATHER/GENS_ERROR_RT


foreach LOCATION ( $LOCATION_LIST )
   echo "====================================================="
   echo "ØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØØ"
   echo

   foreach VARIABLE  ( $VARIABLE_LIST )

         echo "====================================================="
         echo

         echo $LOCATION $VARIABLE  ${START_DATE}_${HH}

         echo
         echo "-----------------------------------------------------"
         echo

         # command-line syntax should read (for example for a fast test case):
         #  ncl 'FILE_LABEL="T2M"' 'scenario="WRFRAP"' 'start_date_string="2016-01-01"' 'end_date_string="2016-01-10"'  script_T2M_read_ensembles_from_thredds.ncl

         echo ncl file_label='"'${VARIABLE}'"' \
                  scenario='"'${LOCATION}'"' \
                  start_date_string='"'${START_DATE}'"'   \
                  end_date_string='"'${END_DATE}'"'       \
                  working_hour='"'$HH'"'       \
                  script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
         echo


         ncl file_label='"'$VARIABLE'"' \
             scenario='"'$LOCATION'"' \
             start_date_string='"'${START_DATE}'"'   \
             end_date_string='"'${END_DATE}'"'       \
             working_hour='"'$HH'"'       \
             script_${VARIABLE}_read_ensembles_from_thredds.ncl

         echo
         echo "-----------------------------------------------------"
         echo



         if ( ${VARIABLE} == "ISOHGT"   &&  ${LOCATION} == "WRFRAP" ) then


            # command-line syntax should read (for example for a fast test case):
            #  ncl 'FILE_LABEL="ISOHGT"' 'scenario="WRFRAP"' 'start_date_string="2017-03-14"' 'end_date_string="2017-03-16"' 'working_hour="12"' script_plot_triangle_product_ISOHGT.ncl

            echo ncl file_label='"'${VARIABLE}'"' \
                     scenario='"'${LOCATION}'"' \
                     start_date_string='"'${START_DATE}'"'   \
                     end_date_string='"'${END_DATE}'"'       \
                     working_hour='"'$HH'"'       \
                     script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
            echo


            ncl file_label='"'$VARIABLE'"' \
                scenario='"'$LOCATION'"' \
                start_date_string='"'${START_DATE}'"'   \
                end_date_string='"'${END_DATE}'"'       \
                working_hour='"'$HH'"'       \
                script_plot_triangle_product_ISOHGT.ncl

            echo
            echo "-----------------------------------------------------"
            echo


         endif

   end





   echo
   echo "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
   echo


end
