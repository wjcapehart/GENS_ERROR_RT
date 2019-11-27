
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Program walks through the SDSMT THREDDS server and extracts the 500 hPa
;      fields from the GEFS ensembles and produce a basic CI triangle
;
;  Known problem: There is a current limit of 240 OPeNDAP files that can be
;      opened at which point further queries will create a 404 error (file not
;      found).  This can be mitigated by processing in short hops and
;      concatening the output with the ncrcat command.
;
;      ncrcat -h file_A.nc file_B.nc file_C.nc MergedFile_ABC.nc
;
;      For the application shown here we will likely need to move away from
;      OPeNDAP/THREDDS and use the local file system unless NCAR-CISL resolves
;      this problem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin

   ;;;;;;;Time Control;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

      ;start_date_string = "2016-01-01"  ; start date
      ;end_date_string   = "2016-01-10"  ; end date
      ;scenario          = "WRFRAP"
      ;working_hour      = "00"
      ;file_label        = "T2M"

   print("Start = " + start_date_string + " " + working_hour + " UTC")
   print("  End = " + end_date_string   + " " + working_hour + " UTC")
   print(" Site = " + scenario)
   print("  Var = " + file_label)

   archive_directory  = "/projects/BIG_WEATHER/wjc/GENS_Processing/arch/"
   error_directory    = "/projects/BIG_WEATHER/GENS_ERROR_RT/error_data/"
   graphics_directory = "/projects/BIG_WEATHER/GENS_ERROR_RT/ci_graphics/"
   archive_directory  = "/projects/BIG_WEATHER/GENS_ERROR_RT/triangle_archives/"
   pdf_directory      = "/projects/BIG_WEATHER/GENS_ERROR_RT/error_pdfs/"


   time_intervals       = 6          ; hours between fx products
   time_intervals@units = "hours"

   ;
   ; We are opening a LOT of files.  More than NCL normally expects.  We will
   ;    need to set the option to allow more 1024 files to be opened.
   ;

   ;setfileoption("nc", "SuppressClose", False)
   setfileoption("nc", "Format",          "NetCDF4")
   setfileoption("nc", "CompressionLevel",        6)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; Site Location
   ;

   location_string = scenario

   ;
   ; requested isobaric height level
   ;
   isobaric_height_pull = (/   10000.0,  \
                               15000.0,  \
                               20000.0,  \
                               25000.0,  \
                               30000.0,  \
                               35000.0,  \
                               40000.0,  \
                               45000.0,  \
                               50000.0,  \
                               55000.0,  \
                               60000.0,  \
                               65000.0,  \
                               70000.0,  \
                               75000.0,  \
                               80000.0,  \
                               85000.0,  \
                               90000.0,  \
                               92500.0,  \
                               95000.0,  \
                               97500.0,  \
                              100000.0   /) ; it's in Pascals

   isobaric_height_pull@units = "Pa"

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Locking in the Location to Extract Data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; root director for THREDDS directories
   ;

   URL = "/data/NCAR/GENS/grib2data/"
   latitude_name  = "lat_0"
   longitude_name = "lon_0"
   time_name      = "forecast_time0"
   isobaricz_name  = "lv_ISBL0"
   isobarich_name  = "lv_ISBL1"
   isobaricw_name  = "lv_ISBL2"
   ensemble_name  = "ensemble0"
   variable_name  = "TMP_P1_L103_GLL0"
   mslp_name      = "PRMSL_P1_L101_GLL0"

   URL = "http://kyrill.ias.sdsmt.edu:8080/thredds/dodsC/BWW_GENS/"
   latitude_name   = "lat"
   longitude_name  = "lon"
   time_name       = "time"
   isobaricz_name  = "isobaric"
   isobarich_name  = "isobaric1"
   isobaricw_name  = "isobaric2"
   ensemble_name   = "ens"
   variable_name   = "Temperature_height_above_ground_ens"
   mslp_name       = "Pressure_reduced_to_MSL_msl_ens"

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; Developing the Time Coordinates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; creating the long time variable from start to end...
   ;
   start_time        = 0
   start_time@units  = "days since " + start_date_string + " " + working_hour + ":00:00"

   end_time          = 0
   end_time@units    = "days since " +  end_date_string  + " " + working_hour + ":00:00"

   ;
   ; Using a common date reference coordinate
   ;

   time_units = "hours since 2016-01-01 00:00:00"

   ;
   ; cd_convert changes both the start and end time to same reference time
   ;

   start_time_arch = toint(cd_convert(start_time, time_units))
   end_time_arch   = toint(cd_convert(end_time,   time_units))


   ;
   ; Time Coordinate Created
   ;

   time = ispan(start_time_arch, end_time_arch, time_intervals)
      time!0             = "time"
      time&time          = time
      time@description   = "time"
      time@long_name     = "time"
      time@standard_name = "time"
      time@calendar      = "standard"
      time@units         = time_units
      time@axis          = "T"


   nt = dimsizes(time)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




   ;;;; Getting the Datasets Common Coordinates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;  Get a single file to pull the latitude, longitude, etc.
   ;

   print("------------  Pulling Metadata  ------------")

   metadata_URL = URL           + \
                  "2017/11/01/" + \
                  "gens003_"    + \
                  scenario      + \
                  "_ALL_2017-11-01_00.wrf_ci_turb.grib2"

   f = addfile(metadata_URL, "r")
   print(metadata_URL)


   lon = f->$longitude_name$
   lon!0 =  "lon"
   lon&lon = lon
   lon@description   = "Longitude"
   lon@long_name     = "Longitude"
   lon@standard_name = "longitude"
   lon@units         = "degrees_east"
   lon@domain_width  = (/ max(lon)-min(lon)  /)
   lon@grid_spacing  = (/ lon(1)-lon(0) /)
   lon@axis          = "X"



   lat = f->$latitude_name$
   lat!0 = "lat"
   lat&lat = lat
   lat@description   = "Latitude"
   lat@long_name     = "Latitude"
   lat@standard_name = "latitude"
   lat@units         = "degrees_north"
   lat@domain_width  = (/ max(lat)-min(lat)  /)
   lat@grid_spacing  = (/ lat(1)-lat(0) /)
   lat@axis          = "Y"


      ;location_string = avg(lon)
         location_string!0             =  "ncl_scalar"
         location_string@description   = "Station Location Label"
         location_string@long_name     = "Station Location Label"



      lon_center = avg(lon)
         lon_center!0             =  "ncl_scalar"
         lon_center@description   = "Longitude Center of Domain"
         lon_center@long_name     = "Longitude Center of Domain"
         lon_center@standard_name = "longitude"
         lon_center@units         = "degrees_east"
         lon_center@domain_width  = (/ max(lon)-min(lon)  /)
         lon_center@grid_spacing  = (/ lon(1)-lon(0) /)
         lon_center@axis          = "X"


      lat_center = avg(lat)
         lat_center!0 =  "ncl_scalar"
         lat_center@description   = "Latitude Center of Domain"
         lat_center@long_name     = "Latitude Center of Domain"
         lat_center@standard_name = "latitude"
         lat_center@units         = "degrees_north"
         lat_center@domain_width  = (/ max(lat)-min(lat)  /)
         lat_center@grid_spacing  = (/ lat(1)-lat(0) /)
         lat_center@axis          = "Y"





   ens = f->$ensemble_name$

   fx  = f->$time_name$
      fx!0     = "fx"
      fx@units = "hours"
      fx@long_name = "Forecast Time"
      fx@description = "Forecast Time"
      delete(fx@calendar)


   isobaric_height = f->$isobaricz_name$({isobaric_height_pull})
   isobaric_height!0 = "isobaric_height"
   isobaric_height&isobaric_height = isobaric_height
   isobaric_height@axis = "Z"
   isobaric_height@standard_name = "pressure"
   isobaric_height@long_name = "Isobaric surface"
   isobaric_height@description = "Isobaric surface"
   isobaric_height@positive = "down"


   elevation_of_mean_sea_level = (/ 0. /)
   elevation_of_mean_sea_level!0 = "elevation_of_mean_sea_level"
   elevation_of_mean_sea_level&elevation_of_mean_sea_level = elevation_of_mean_sea_level
   elevation_of_mean_sea_level@long_name     = "Elevation of Mean Sea Level"
   elevation_of_mean_sea_level@description   = "Elevation of Mean Sea Level"
   elevation_of_mean_sea_level@standard_name = "altitude"
   elevation_of_mean_sea_level@units = "m"
   elevation_of_mean_sea_level@axis = "Z"

   elevation_of_screen_height = elevation_of_mean_sea_level
   elevation_of_screen_height(:) = (/ 2. /)
   elevation_of_screen_height@long_name     = "Elevation of Standard Screen Height"
   elevation_of_screen_height@description   = "Elevation of Standard Screen Height"
   elevation_of_screen_height!0 = "elevation_of_screen_height"
   elevation_of_screen_height&elevation_of_screen_height = elevation_of_screen_height

   elevation_of_anemometer_height = elevation_of_mean_sea_level
   elevation_of_anemometer_height(:) = (/ 10. /)
   elevation_of_anemometer_height@long_name     = "Elevation of Standard Anemometer Height"
   elevation_of_anemometer_height@description   = "Elevation of Standard Anemometer Height"
   elevation_of_anemometer_height!0 = "elevation_of_anemometer_height"
   elevation_of_anemometer_height&elevation_of_anemometer_height = elevation_of_anemometer_height

   elevation_at_ground_surface = elevation_of_mean_sea_level
   elevation_at_ground_surface@long_name     = "Elevation at Ground Surface"
   elevation_at_ground_surface@description   = "Elevation at Ground Surface"
   elevation_at_ground_surface!0 = "elevation_at_ground_surface"
   elevation_at_ground_surface&elevation_at_ground_surface = elevation_at_ground_surface

   nx   = dimsizes(lon)
   ny   = dimsizes(lat)
   nens = dimsizes(ens)
   nfx  = dimsizes(fx)
   np   = dimsizes(isobaric_height)
   nz   = dimsizes(elevation_of_anemometer_height)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Realtime to Forecast Time ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; Create array to line up the forecast_product time to calendar time
   ;

   print("------------  Setting Time-Fx Coordinates Lookups for Forecast and Verification Times  ------------")

   forecast_valid_time = new((/ nt, nfx /), float )
      forecast_valid_time!0           = "time"
      forecast_valid_time!1           = "fx"
      forecast_valid_time&time        = time
      forecast_valid_time&fx          = fx
      forecast_valid_time@long_name = "Valid Time Coordinate for Forecast Times"
      forecast_valid_time@description = "Valid Time Coordinate for Forecast Times"
      forecast_valid_time@standard_name = "time"
      forecast_valid_time@units       = time_units
      forecast_valid_time@calendar    = "standard"

   forecast_valid_time_string = new((/ nt, nfx /), string )
      forecast_valid_time_string!0           = "time"
      forecast_valid_time_string!1           = "fx"
      forecast_valid_time_string&time        = time
      forecast_valid_time_string&fx          = fx
      forecast_valid_time_string@description = "Date Stamp Forecast Times"
      forecast_valid_time_string@long_name = "Date Stamp Forecast Times"

   forecast_product_time_string = new((/ nt, nfx /), string )
      forecast_product_time_string!0           = "time"
      forecast_product_time_string!1           = "fx"
      forecast_product_time_string&time        = time
      forecast_product_time_string&fx          = fx
      forecast_product_time_string@description = "Date Stamp Forecast Product Times"
      forecast_product_time_string@long_name   = "Date Stamp Forecast Product Times"

   do t = 0, nt-1
      do ifx = 0, nfx-1

         forecast_valid_time(t,ifx) = time(t) + toint(fx(ifx))

         product_time_decompose = cd_calendar(time(t), -5)
         valid_time_decompose   = cd_calendar(forecast_valid_time(t,ifx), -5)

         valid_time = sprinti("%0.4i-", valid_time_decompose(0,0)) + \
                      sprinti("%0.2i-", valid_time_decompose(0,1)) + \
                      sprinti("%0.2i_", valid_time_decompose(0,2)) + \
                      sprinti("%0.2i",  valid_time_decompose(0,3))

         product_time = sprinti("%0.4i-",  product_time_decompose(0,0)) + \
                        sprinti("%0.2i-",  product_time_decompose(0,1)) + \
                        sprinti("%0.2i_",  product_time_decompose(0,2)) + \
                        sprinti("%0.2i_F", product_time_decompose(0,3)) + \
                        sprinti("%0.2i",   toint(fx(ifx)))

         forecast_valid_time_string(t,ifx)   = valid_time
         forecast_product_time_string(t,ifx) = product_time

      end do
   end do

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Create a Singular Height Fields ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;  Create a single time array to carry all of the ensemble data
   ;

   print("------------  Initializing 2-D Fields  ------------")

   mean_sea_level_pressure_field = new((/ nt, nfx, nens, nz, ny, nx /), float)
      mean_sea_level_pressure_field!0        = "time"
      mean_sea_level_pressure_field!1        = "fx"
      mean_sea_level_pressure_field!2        = "ens"
      mean_sea_level_pressure_field!3        = "elevation_of_mean_sea_level"
      mean_sea_level_pressure_field!4        = "lat"
      mean_sea_level_pressure_field!5        = "lon"
      mean_sea_level_pressure_field&time     = time
      mean_sea_level_pressure_field&fx       = fx
      mean_sea_level_pressure_field&ens      = ens
      mean_sea_level_pressure_field&elevation_of_mean_sea_level = elevation_of_mean_sea_level
      mean_sea_level_pressure_field&lat      = lat
      mean_sea_level_pressure_field&lon      = lon
      copy_VarAtts(f->$mslp_name$, mean_sea_level_pressure_field)
      delete(mean_sea_level_pressure_field@coordinates)
      mean_sea_level_pressure_field@_FillValue    = default_fillvalue(typeof(mean_sea_level_pressure_field))
      mean_sea_level_pressure_field@missing_value = mean_sea_level_pressure_field@_FillValue
      mean_sea_level_pressure_field@description   = "Surface Pressure Reduced to Mean Sea Level (all members)"
      mean_sea_level_pressure_field@long_name     = mean_sea_level_pressure_field@description
      mean_sea_level_pressure_field@standard_name = "air_pressure_at_sea_level"
      mean_sea_level_pressure_field(:, :, :, :, :, :) = mean_sea_level_pressure_field@_FillValue


   temperature_at_2m_agl_field =  mean_sea_level_pressure_field
      copy_VarAtts(f->$variable_name$, temperature_at_2m_agl_field)
      temperature_at_2m_agl_field!3        = "elevation_of_screen_height"
      temperature_at_2m_agl_field&elevation_of_screen_height = elevation_of_screen_height
      temperature_at_2m_agl_field@description   = "2-m Air Temperature (all members)"
      temperature_at_2m_agl_field@long_name     = "2-m Air Temperature (all members)"
      temperature_at_2m_agl_field@standard_name = "air_temperature"
      temperature_at_2m_agl_field@units         = "K"
      delete(temperature_at_2m_agl_field@coordinates)
      temperature_at_2m_agl_field@_FillValue    = default_fillvalue(typeof(temperature_at_2m_agl_field))
      temperature_at_2m_agl_field@missing_value = temperature_at_2m_agl_field@_FillValue

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Time for the Reading Loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   print("------------  Reading Data from  Server  ------------")

   delete(f)
   fileopen = 0
   do t = 0, nt-1
      ; create year-month-day hour:minute fields
      ;    with the date_decompose function.
      ;
      date_decompose = cd_calendar(time(t), -5)

      day_dir = sprinti("%0.4i/", date_decompose(0,0)) + \
                sprinti("%0.2i/", date_decompose(0,1)) + \
                sprinti("%0.2i/", date_decompose(0,2))

      fx_time = sprinti("%0.4i-", date_decompose(0,0)) + \
                sprinti("%0.2i-", date_decompose(0,1)) + \
                sprinti("%0.2i_", date_decompose(0,2)) + \
                sprinti("%0.2i",  date_decompose(0,3))

      ;
      ; Create the GENS SDSMT-processed file
      ;

      single_file = "gens003_"           + \
                    scenario             + \
                    "_ALL_"              + \
                    fx_time              + \
                    ".wrf_ci_turb.grib2"

      full_file_URL = URL + day_dir + single_file

      ;
      ; Only do if the data file exists
      ;

      if ( isfilepresent(full_file_URL) ) then
         fileopen = fileopen + 1

         print(sprinti("%0.5i ", fileopen) + "---"+full_file_URL)

         f = addfile(full_file_URL, "r")

         ;
         ; Pull native file iso
         ;

         z_isobaric  = f->$isobaricz_name$
         rh_isobaric = f->$isobarich_name$
         w_isobaric =  f->$isobaricw_name$

         ;
         ; Extract the fields
         ;


         if ( isfilevar(f,variable_name) ) then
            inarr =  f->$variable_name$
            replace_ieeenan(inarr, inarr@_FillValue, 0)

            inarr!0 = "thredds_fx"
            inarr!1 = "thredds_ens"
            thredds_fx  = inarr&thredds_fx
            thredds_ens = inarr&thredds_ens
            temperature_at_2m_agl_field( t, {thredds_fx}, {thredds_ens}, 0, :, :) = (/ inarr({thredds_fx},{thredds_ens},0,:,:) /)
            if (dimsizes(thredds_fx).ne.dimsizes(fx)) then
               print("      !!!!  Error in "+fx_time+" Fx size for " + variable_name)
            end if
            if (dimsizes(thredds_ens).ne.dimsizes(ens)) then
               print("      !!!!  Error in "+fx_time+" Ens size for " + variable_name)
            end if
            delete(thredds_fx)
            delete(thredds_ens)
            delete(inarr)
         end if
         delete(z_isobaric)
         delete(rh_isobaric)
         delete(w_isobaric)
      end if


   end do

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Generate StDev by Forecast and Forecast Time ;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; This takes advangate of the dim_stddev_n_Wrap
   ;   function calculates stdev over a range of indexes, in this case
   ;   the ensembles
   ;
   ;  input indicies:    [time] x [fx] x [ens] x [isobaric] x [lat] x [lon]
   ;
   ;  remaining output indexes : [time] x [fx] x [isobaric] x [lat] x [lon]

   print("------------  Calculating Spatially-Distributed Standard Deviation Fields  ------------")

   temperature_at_2m_agl_xy_stdev = dim_stddev_n_Wrap(temperature_at_2m_agl_field, 2)
   temperature_at_2m_agl_xy_stdev@cell_method   = "ens:standard_deviation"
   temperature_at_2m_agl_xy_stdev@long_name     = "2-m Air Temperature StDev by Lat-Lon"
   temperature_at_2m_agl_xy_stdev@description   = temperature_at_2m_agl_xy_stdev@long_name



   ; Average stdevs across latitudes and longitudes
   ;  input indexes            : [time] x [fx] x [isobaric] x [lat] x [lon]
   ;  remaining output indexes : [time] x [fx] x [isobaric]

   print("------------  Calculating Spatially-Averaged Standard Deviation Fields  ------------")


      temperature_at_2m_agl_stdev = dim_avg_n_Wrap(temperature_at_2m_agl_xy_stdev, (/ 3, 4 /))
      temperature_at_2m_agl_stdev@long_name     = "2-m Air Temperature StDev"
      temperature_at_2m_agl_stdev@description   = "2-m Air Temperature StDev"
      temperature_at_2m_agl_stdev@standard_name = "air_temperature"
      temperature_at_2m_agl_stdev@cell_method   = "ens:standard_deviation lon:mean lat:mean"


   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; Generate Std and Means in X-Y directions ;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; This takes advangate of the dim_stddev_n_Wrap & dim_avg_n_Wrap
   ;   function calculates stdev over a range of indexes, in this case
   ;   the ensembles
   ;
   ;  input indicies:    [time] x [fx] x [ens] x [isobaric] x [lat] x [lon]
   ;
   ;  remaining output indexes : [time] x [fx] x [ens] x [isobaric]

   print("------------  Calculating Mean and Stdev by Ensemble Layer   ------------")

      temperature_at_2m_agl_stdev_by_ens               = dim_stddev_n_Wrap(temperature_at_2m_agl_field, (/ 4, 5 /))
      temperature_at_2m_agl_stdev_by_ens@cell_method   = "lon: lat: standard_deviation"
      temperature_at_2m_agl_stdev_by_ens@long_name     = "2-m Air Temperature StDev by Member"
      temperature_at_2m_agl_stdev_by_ens@description   = temperature_at_2m_agl_stdev_by_ens@long_name

      temperature_at_2m_agl_avg_by_ens               = dim_avg_n_Wrap(temperature_at_2m_agl_field, (/ 4, 5 /))
      temperature_at_2m_agl_avg_by_ens@cell_method   = "lon: lat: mean"
      temperature_at_2m_agl_avg_by_ens@long_name     = "2-m Air Temperature Mean by Member"
      temperature_at_2m_agl_avg_by_ens@description   = temperature_at_2m_agl_avg_by_ens@long_name

      ;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Generate Spatial RMSE Metrics ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;  Root Mean Squared for Each Spatial Point
   ;
   ; Validation Field uses the mean of all ensembles for forecast at hour 0

   print("------------  Creating Spatially-Distributed RMSE Fields  ------------")

   temperature_at_2m_agl_xy_rmse = temperature_at_2m_agl_xy_stdev
   temperature_at_2m_agl_xy_rmse@long_name     = "2-m Air Temperature RMSE by Lat-Lon"
   temperature_at_2m_agl_xy_rmse@description   = temperature_at_2m_agl_xy_rmse@long_name
   temperature_at_2m_agl_xy_rmse@cell_method   = "ens:rmse"
   temperature_at_2m_agl_xy_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens" ;"
   temperature_at_2m_agl_xy_rmse(:,:,:,:,:)      = temperature_at_2m_agl_xy_rmse@_FillValue
   delete(temperature_at_2m_agl_xy_rmse@stddev_op_ncl)
   temperature_at_2m_agl_xy_rmse@kolczynski_equivalent = "sqrt[AVars(sij)]"

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; Generate Error Metrics ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; Calculate the Error for both the master ensemble member (ens # 0) and
   ;    across all ensembles.
   ;
   ;  in variable : [time] x [fx] x [ens] x [isobaric] x [lat] x [lon]
   ;
   ;  final index : [time] x [fx] x         [isobaric]

   print("------------  Creating Spatially-Averaged RMSE Fields  ------------")



   temperature_at_2m_agl_ens000_rmse               = temperature_at_2m_agl_stdev
   temperature_at_2m_agl_ens000_rmse@long_name     = "2-m Air Temperature RMSE (control member)"
   temperature_at_2m_agl_ens000_rmse@description   = temperature_at_2m_agl_ens000_rmse@description
   temperature_at_2m_agl_ens000_rmse@ensemble      = "Ensemble Member #00"
   temperature_at_2m_agl_ens000_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens|0, lat,lon"
   temperature_at_2m_agl_ens000_rmse@cell_method   = "lon: lat: rmse"
   temperature_at_2m_agl_ens000_rmse(:,:,:)        = temperature_at_2m_agl_ens000_rmse@_FillValue

   temperature_at_2m_agl_ensALL_rmse               = temperature_at_2m_agl_ens000_rmse
   temperature_at_2m_agl_ensALL_rmse@long_name     = "2-m Air Temperature RMSE (all members)"
   temperature_at_2m_agl_ensALL_rmse@description   = temperature_at_2m_agl_ensALL_rmse@long_name
   temperature_at_2m_agl_ensALL_rmse@ensemble      = "All 21 Ensemble Members"
   temperature_at_2m_agl_ensALL_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens,lat,lon"
   temperature_at_2m_agl_ensALL_rmse@cell_method   = "ens: lon: lat: rmse"
   temperature_at_2m_agl_ensALL_rmse(:,:,:)        = temperature_at_2m_agl_ensALL_rmse@_FillValue

   temperature_at_2m_agl_ensAVG_rmse               = temperature_at_2m_agl_ens000_rmse
   temperature_at_2m_agl_ensAVG_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens,lat,lon"
   temperature_at_2m_agl_ensAVG_rmse@avg_op_ncl    = "dim_avg_n over dimension(s): ens"
   temperature_at_2m_agl_ensAVG_rmse@ensemble      = "All 21 Ensemble Members"
   temperature_at_2m_agl_ensAVG_rmse@long_name     = "2-m Air Temperature RMSE (ensemble mean)"
   temperature_at_2m_agl_ensAVG_rmse@description   = temperature_at_2m_agl_ensAVG_rmse@long_name
   temperature_at_2m_agl_ensAVG_rmse@cell_method   = "ens:mean  lon: lat: rmse"
   temperature_at_2m_agl_ensAVG_rmse(:,:,:)        = temperature_at_2m_agl_ensAVG_rmse@_FillValue
   temperature_at_2m_agl_ensAVG_rmse@kolczynski_equivalent = "avg(AVars(s),xy)"
   temperature_at_2m_agl_xy_stdev@kolczynski_equivalent = "EVars(sij)"

   temperature_at_2m_agl_corr_by_ens               = temperature_at_2m_agl_stdev_by_ens
   temperature_at_2m_agl_corr_by_ens@long_name     = "2-m Air Temperature Corr by Member"
   temperature_at_2m_agl_corr_by_ens@description   = temperature_at_2m_agl_corr_by_ens@description
   temperature_at_2m_agl_corr_by_ens@cell_method   = "lon: lat: corr"
   temperature_at_2m_agl_corr_by_ens(:,:,:,:)        = temperature_at_2m_agl_corr_by_ens@_FillValue

   temperature_at_2m_agl_bias_by_ens               = temperature_at_2m_agl_stdev_by_ens
   temperature_at_2m_agl_bias_by_ens@long_name     = "2-m Air Temperature Bias by Member"
   temperature_at_2m_agl_bias_by_ens@description   = temperature_at_2m_agl_bias_by_ens@description
   temperature_at_2m_agl_bias_by_ens@cell_method   = "lon: lat: bias"
   temperature_at_2m_agl_bias_by_ens(:,:,:,:)        = temperature_at_2m_agl_bias_by_ens@_FillValue


   temperature_at_2m_agl_rmse_by_ens               = temperature_at_2m_agl_stdev_by_ens
   temperature_at_2m_agl_rmse_by_ens@long_name     = "2-m Air Temperature RMSE by Member"
   temperature_at_2m_agl_rmse_by_ens@description   = temperature_at_2m_agl_rmse_by_ens@description
   temperature_at_2m_agl_rmse_by_ens@cell_method   = "lon: lat: rmse"
   temperature_at_2m_agl_rmse_by_ens(:,:,:,:)        = temperature_at_2m_agl_rmse_by_ens@_FillValue


   ; there has to be a beautifully elegant way to get this fast but I don't
   ;   haven't thought of it yet
   ;
   ; We first match the forecast valid time with the respective analysis (F00)
   ;

   print("------------  Calculating RMSE Fields  ------------")

   do ifx = 0, nfx-1

      do t = 0, nt-1

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

         ; We first match the forecast valid time with the
         ;      respective analysis (F00) and locate both indices

         model_forecast_time = forecast_valid_time(t,ifx)

         ; Get the index for F00 forecast where we are at the model valid time
         ;    if you fall off the end of your forecast run, it is taken as a
         ;    missing value

         index_validation_time = ind(time .eq. forecast_valid_time(t,ifx))

         ; At the ends of our forecast run just don't do those.

         if (.not.ismissing(index_validation_time)) then

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            temp_model0    := temperature_at_2m_agl_field(                    t, ifx, 0, :, :, :)
            temp_analysis0 := temperature_at_2m_agl_field(index_validation_time,   0, 0, :, :, :)

            rmse0  := dim_rmsd_n_Wrap(temp_model0, temp_analysis0, (/ 1,2 /) )
            replace_ieeenan(rmse0, rmse0@_FillValue, 0)

            temperature_at_2m_agl_ens000_rmse(t,ifx,:) = (/ rmse0 /)

            ;...................................................................

            temp_modelA    := temperature_at_2m_agl_field(time |                     t, fx | ifx, elevation_of_screen_height | :, ens | :, lat | :, lon | :)
            temp_analysisA := temperature_at_2m_agl_field(time | index_validation_time, fx |   0, elevation_of_screen_height | :, ens | :, lat | :, lon | :)

            rmseA := dim_rmsd_n_Wrap(temp_modelA, temp_analysisA, (/ 1,2,3 /) )
            replace_ieeenan(rmseA, rmseA@_FillValue, 0)

            temperature_at_2m_agl_ensALL_rmse(t,ifx,:) = (/ rmseA /)

            ;...................................................................

            temp_modelM    := dim_avg_n_Wrap(temperature_at_2m_agl_field(                    t, ifx, :, :, :, :), 0)
            temp_analysisM := dim_avg_n_Wrap(temperature_at_2m_agl_field(index_validation_time,   0, :, :, :, :), 0)

            rmseM := dim_rmsd_n_Wrap(temp_modelM, temp_analysisM, (/ 1,2 /) )
            replace_ieeenan(rmseM, rmseM@_FillValue, 0)

            temperature_at_2m_agl_ensAVG_rmse(t,ifx,:) = (/ rmseM /)

            ;...................................................................

            temp_modelX    := temperature_at_2m_agl_field(                    t, ifx, :, :, :, :)
            temp_analysisX := conform_dims(dimsizes(temp_modelX(                                            :,  :, :, :)),    \
                                      dim_avg_n_Wrap(temperature_at_2m_agl_field(index_validation_time,   0, :,  :, :, :), 0), \
                                      (/ 1,2,3  /) )

            rmseM := dim_rmsd_n_Wrap(temp_modelX, temp_analysisX, 0 )
            replace_ieeenan(rmseM, rmseM@_FillValue, 0)

            temperature_at_2m_agl_xy_rmse(t,ifx,:,:,:) = (/ rmseM /)

            ;...................................................................

            temp_modelE    := temperature_at_2m_agl_field(                    t, ifx, :, :, :, :)
            temp_analysisE := temperature_at_2m_agl_field(index_validation_time,   0, :, :, :, :)

            biasE := dim_avg_n_Wrap((/ (temp_modelE - temp_analysisE)  /), (/ 2, 3 /) )
            replace_ieeenan(biasE, biasE@_FillValue, 0)

            temperature_at_2m_agl_bias_by_ens(t,ifx,:,:) = (/ biasE /)

            rmseE := dim_rmsd_n_Wrap(temp_modelE, temp_analysisE, (/ 2, 3 /) )
            replace_ieeenan(rmseE, rmseE@_FillValue, 0)

            temperature_at_2m_agl_rmse_by_ens(t,ifx,:,:) = (/ rmseE /)

            do ee = 0, nens-1
               do zz = 0, nz-1
                  temp_modelEn    := temp_modelE(   ee,zz,:,:)
                  temp_analysisEn := temp_analysisE(ee,zz,:,:)
                  corrE := escorc(ndtooned(temp_modelEn),ndtooned(temp_analysisEn))
                  replace_ieeenan(corrE, corrE@_FillValue, 0)
                  temperature_at_2m_agl_corr_by_ens(t,ifx,ee,zz) = (/ corrE /)
               end do
            end do

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            print(sprinti("t%0.5i_", t) + sprinti("f%0.2i", ifx) + \
                  "_vs_" + sprinti("t%0.5i", index_validation_time) + " | " + \
                  sprinti("%0.5i_",   toint(time(t))) +   \
                  sprinti("F%0.2i",   toint(fx(ifx))) + " " +  \
                  forecast_valid_time_string(t,ifx) + " " + \
                  forecast_valid_time_string(index_validation_time,0) + " " + \
                  temperature_at_2m_agl_ens000_rmse( t,ifx,0) + " " + \
                  temperature_at_2m_agl_bias_by_ens(t,ifx,0,0) + " " + \
                  temperature_at_2m_agl_corr_by_ens(t,ifx,0,0) )

         end if

      end do

   end do


   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




   ;;;; Drop Output to File  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   ;
   ; Create Output File
   ;

   print("------------  Writing Output File  ------------")

   output_file = error_directory+ "GENS_03_ENSEMBLE__"+file_label+"__ERROR__" + \
                 scenario + "__" + \
                 start_date_string + "_" + working_hour + "_to_" + \
                 end_date_string + "_" + working_hour + ".nc"

   print("OUTPUT NETCDF FILE: "+output_file)

   ;
   ; Destroy previous instances of output file
   ;

   system("rm -frv " + output_file)

   ;
   ; create temporary file
   ;

   fout = addfile(output_file, "c")

      fout@title = "GENS Ensemble Variance and Error for Region " + \
                  scenario + " " +                                 \
                  start_date_string + "_" + working_hour + "_to_" + \
                  end_date_string + "_" + working_hour


      fout@institution       = "SD School of Mines and Big Weather Web Project"
      fout@author            = "Bill Capehart, SD-Mines, William.Capehart@sdsmt.edu"
      fout@source            = "NCEP GENS WMO Grid 003 Model Ensembles"
      fout@Conventions       = "CF-1.7"
      fout@project_url       = "http://bigweatherweb.org/Big_Weather_Web/Home/Home.html"
      fout@model_url         = "http://www.emc.ncep.noaa.gov/index.php?branch=GEFS"
      fout@original_product_wmo_grid = "http://www.nco.ncep.noaa.gov/pmb/docs/on388/tableb.html#GRID3"
      fout@product_grid_spacing = "1 degrees_east x 1 degrees_north"


      fout@total_number_of_ensembles = nens

      fout@project_subdomain_name = scenario

      fout@subdomain_min_lon = min(lon)
      fout@subdomain_max_lon = max(lon)
      fout@subdomain_min_lat = min(lat)
      fout@subdomain_max_lat = max(lat)

      fout@start_date = start_date_string
      fout@end_date   = end_date_string

      fout->$time_name$                        = time
      fout->$time_name$                        = time

   delete(fout)

   ;
   ; use NetCDF Command Operators (nco) to set time as the formal record
   ;

   system("ncks -Oh --mk_rec_dmn time " + output_file + " deleteme.nc")
   system("mv -v deleteme.nc  " + output_file )

   ;
   ; finish dropping the output into the netcdf file
   ;

   fout = addfile(output_file, "w")

      fout->location_label                     = location_string
      fout->lon_center                         = lon_center
      fout->lat_center                         = lat_center
      fout->fx                                 = fx
      fout->isobaric_height                    = isobaric_height
      fout->ens                                = ens
      fout->elevation_of_mean_sea_level        = elevation_of_mean_sea_level
      fout->elevation_of_screen_height         = elevation_of_screen_height
      fout->elevation_of_anemometer_height     = elevation_of_anemometer_height
      fout->elevation_at_ground_surface        = elevation_at_ground_surface

      fout->forecast_valid_time                = forecast_valid_time

      fout->temperature_at_2m_agl_xy_stdev     = temperature_at_2m_agl_xy_stdev
      fout->temperature_at_2m_agl_xy_rmse      = temperature_at_2m_agl_xy_rmse
      fout->temperature_at_2m_agl_stdev        = temperature_at_2m_agl_stdev
      fout->temperature_at_2m_agl_ens000_rmse  = temperature_at_2m_agl_ens000_rmse
      fout->temperature_at_2m_agl_ensALL_rmse  = temperature_at_2m_agl_ensALL_rmse
      fout->temperature_at_2m_agl_ensAVG_rmse  = temperature_at_2m_agl_ensAVG_rmse

      fout->temperature_at_2m_agl_corr_by_ens  = temperature_at_2m_agl_corr_by_ens
      fout->temperature_at_2m_agl_bias_by_ens  = temperature_at_2m_agl_bias_by_ens
      fout->temperature_at_2m_agl_rmse_by_ens  = temperature_at_2m_agl_rmse_by_ens

      fout->temperature_at_2m_agl_avg_by_ens   = temperature_at_2m_agl_avg_by_ens
      fout->temperature_at_2m_agl_stdev_by_ens = temperature_at_2m_agl_stdev_by_ens

   delete(fout)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



end
