
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

   print("Start = " + start_date_string + " " + working_hour + " UTC")
   print("  End = " + end_date_string   + " " + working_hour + " UTC")
   print(" Site = " + scenario)
   print("  Var = " + file_label)


   ;start_date_string = "2015-12-25"  ; start date
   ;end_date_string   = "2017-10-10"  ; end date
   ;scenario = "WRFRAP"
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
   isobaric_height_pull = (/    1000.0,  \
                                2000.0,  \
                                3000.0,  \
                                5000.0,  \
                                7000.0,  \
                               10000.0,  \
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
   URL = "http://kyrill.ias.sdsmt.edu:8080/thredds/dodsC/BWW_GENS/"

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

   lon = f->lon
   lon!0 =  "lon"
   lon&lon = lon
   lon@description   = "Longitude"
   lon@long_name     = "Longitude"
   lon@standard_name = "longitude"
   lon@units         = "degrees_east"
   lon@domain_width  = (/ max(lon)-min(lon)  /)
   lon@grid_spacing  = (/ lon(1)-lon(0) /)
   lon@axis          = "X"



   lat = f->lat
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
         location_string!0 =  "ncl_scalar"
         location_string@description   = "Station Location Label"
         location_string@long_name     = "Station Location Label"



      lon_center = avg(lon)
         lon_center!0 =  "ncl_scalar"
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




   ens = f->ens

   fx  = f->time
      fx!0     = "fx"
      fx@units = "hours"
      fx@long_name = "Forecast Time"
      fx@description = "Forecast Time"
      delete(fx@calendar)


   isobaric_height = f->isobaric({isobaric_height_pull})
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


   ;;;; Create a Isobaric Fields ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;  Create a single time array to carry all of the ensemble data
   ;

   print("------------  Initializing Isobaric Fields  ------------")

   isobaric_height_field = new((/ nt, nfx, nens, np, ny, nx /), float)
      isobaric_height_field!0        = "time"
      isobaric_height_field!1        = "fx"
      isobaric_height_field!2        = "ens"
      isobaric_height_field!3        = "isobaric_height"
      isobaric_height_field!4        = "lat"
      isobaric_height_field!5        = "lon"
      isobaric_height_field&time     = time
      isobaric_height_field&fx       = fx
      isobaric_height_field&ens      = ens
      isobaric_height_field&isobaric_height = isobaric_height
      isobaric_height_field&lat      = lat
      isobaric_height_field&lon      = lon
      copy_VarAtts(f->Geopotential_height_isobaric_ens, isobaric_height_field)
      delete(isobaric_height_field@coordinates)
      isobaric_height_field@_FillValue    = default_fillvalue(typeof(isobaric_height_field))
      isobaric_height_field@missing_value = isobaric_height_field@_FillValue
      isobaric_height_field@description   = "Geopotential Height (all members)"
      isobaric_height_field@long_name     = isobaric_height_field@description
      isobaric_height_field@standard_name = "geopotential_height"
      isobaric_height_field(:, :, :, :, :, :) = isobaric_height_field@_FillValue

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

         z_isobaric  = f->isobaric
         rh_isobaric = f->isobaric1
         w_isobaric =  f->isobaric2

         ;
         ; Extract the fields
         ;

         if ( isfilevar(f,"Geopotential_height_isobaric_ens") ) then
            inarr = f->Geopotential_height_isobaric_ens
            replace_ieeenan(inarr, inarr@_FillValue, 0)
            isobaric_height_field(  t, :, :, {z_isobaric},  :,  :) =    \
                  (/ inarr(  :, :, {z_isobaric}, :, :) /)
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

   isobaric_height_xy_stdev = dim_stddev_n_Wrap(isobaric_height_field, 2)
   isobaric_height_xy_stdev@cell_method   = "ens:standard_deviation"
   isobaric_height_xy_stdev@long_name     = "Isobaric Geopotential Height StDev by Lat-Lon"
   isobaric_height_xy_stdev@description   = isobaric_height_xy_stdev@long_name

   ; Average stdevs across latitudes and longitudes
   ;  input indexes            : [time] x [fx] x [isobaric] x [lat] x [lon]
   ;  remaining output indexes : [time] x [fx] x [isobaric]

   print("------------  Calculating Spatially-Averaged Standard Deviation Fields  ------------")

   isobaric_height_stdev = dim_avg_n_Wrap(isobaric_height_xy_stdev, (/ 3, 4 /))
   isobaric_height_stdev@long_name     = "Isobaric Geopotential Height StDev"
   isobaric_height_stdev@description   = "Isobaric Geopotential Height StDev"
   isobaric_height_stdev@standard_name = "geopotential_height"
   isobaric_height_stdev@cell_method   = "ens:standard_deviation lon:mean lat:mean"

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; Generate Spatial RMSE Metrics ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;  Root Mean Squared for Each Spatial Point
   ;
   ; Validation Field uses the mean of all ensembles for forecast at hour 0

   print("------------  Creating Spatially-Distributed RMSE Fields  ------------")

   isobaric_height_xy_rmse = isobaric_height_xy_stdev
   isobaric_height_xy_rmse@long_name     = "Geopotential Height RMSE by Lat-Lon"
   isobaric_height_xy_rmse@description   = isobaric_height_xy_rmse@long_name
   isobaric_height_xy_rmse@cell_method   = "ens:rmse"
   isobaric_height_xy_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens" ;"
   isobaric_height_xy_rmse(:,:,:,:,:)      = isobaric_height_xy_rmse@_FillValue
   delete(isobaric_height_xy_rmse@stddev_op_ncl)
   isobaric_height_xy_rmse@kolczynski_equivalent = "sqrt[AVars(sij)]"

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

   isobaric_height_ens000_rmse               = isobaric_height_stdev
   isobaric_height_ens000_rmse@long_name     = "Geopotential Height RMSE (control member)"
   isobaric_height_ens000_rmse@description   = "Geopotential Height RMSE (control member)"
   isobaric_height_ens000_rmse@standard_name = "geopotential_height"
   isobaric_height_ens000_rmse@units         = "gpm"
   isobaric_height_ens000_rmse@ensemble      = "Ensemble Member #00"
   isobaric_height_ens000_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens|0, lat,lon"
   isobaric_height_ens000_rmse@cell_method   = "lon: lat: rmse"
   isobaric_height_ens000_rmse(:,:,:)        = isobaric_height_ens000_rmse@_FillValue

   isobaric_height_ensALL_rmse               = isobaric_height_ens000_rmse
   isobaric_height_ensALL_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens,lat,lon"
   isobaric_height_ensALL_rmse@ensemble      = "All 21 Ensemble Members"
   isobaric_height_ensALL_rmse@long_name     = "Geopotential Height RMSE (all members)"
   isobaric_height_ensALL_rmse@description   = "Geopotential Height RMSE (all members)"
   isobaric_height_ensALL_rmse@cell_method   = "ens: lon: lat: rmse"
   isobaric_height_ensALL_rmse(:,:,:)        = isobaric_height_ensALL_rmse@_FillValue

   isobaric_height_ensAVG_rmse               = isobaric_height_ens000_rmse
   isobaric_height_ensAVG_rmse@rmsd_op_ncl   = "dim_rmsd_n over dimension(s): ens,lat,lon"
   isobaric_height_ensAVG_rmse@avg_op_ncl    = "dim_avg_n over dimension(s): ens"
   isobaric_height_ensAVG_rmse@ensemble      = "All 21 Ensemble Members"
   isobaric_height_ensAVG_rmse@long_name     = "Geopotential Height RMSE (ensemble mean)"
   isobaric_height_ensAVG_rmse@description   = "Geopotential Height RMSE (ensemble mean)"
   isobaric_height_ensAVG_rmse@cell_method   = "ens:mean  lon: lat: rmse"
   isobaric_height_ensAVG_rmse(:,:,:)        = isobaric_height_ensALL_rmse@_FillValue
   isobaric_height_ensAVG_rmse@kolczynski_equivalent = "avg(AVars(s),xy)"
   isobaric_height_xy_stdev@kolczynski_equivalent = "EVars(sij)"


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

            ; Start with just the 00 Ensemble.

            ; Extract the model fields and analysis fields

            temp_model0    := isobaric_height_field(                    t, ifx, 0, :, :, :)
            temp_analysis0 := isobaric_height_field(index_validation_time,   0, 0, :, :, :)

            ; For the master one, it's easy and we can use the dim_rmsd_n func

            rmse0 := dim_rmsd_n_Wrap(temp_model0, temp_analysis0, (/ 1,2 /) )
            replace_ieeenan(rmse0, rmse0@_FillValue, 0)

            isobaric_height_ens000_rmse(t,ifx,:) = (/ rmse0 /)

            ; Now try one with ALL of the ensemble members

            ; Extract the model fields and analysis fields

            ; fields must be re-ordered to swap isobaric and ensemble positions.
            ;[time | 161] x [fx | 15] x [ens | 21] x [isobaric | 26] x [lat | 22] x [lon | 22]

            temp_modelA    := isobaric_height_field(time |                     t, fx | ifx, isobaric_height | :, ens | :, lat | :, lon | :)
            temp_analysisA := isobaric_height_field(time | index_validation_time, fx |   0, isobaric_height | :, ens | :, lat | :, lon | :)

            rmseA := dim_rmsd_n_Wrap(temp_modelA, temp_analysisA, (/ 1,2,3 /) )
            replace_ieeenan(rmseA, rmseA@_FillValue, 0)

            isobaric_height_ensALL_rmse(t,ifx,:) = (/ rmseA /)

            ; Finally Average Across all ensemble members and take the RMSE of the result.

            ; Extract the model fields and analysis fields

            ; fields must be re-ordered to swap isobaric and ensemble positions.
            ;[time | 161] x [fx | 15] x [ens | 21] x [isobaric | 26] x [lat | 22] x [lon | 22]

            temp_modelM    := dim_avg_n_Wrap(isobaric_height_field(                    t, ifx, :, :, :, :), 0)
            temp_analysisM := dim_avg_n_Wrap(isobaric_height_field(index_validation_time,   0, :, :, :, :), 0)

            rmseM := dim_rmsd_n_Wrap(temp_modelM, temp_analysisM, (/ 1,2 /) )
            replace_ieeenan(rmseM, rmseM@_FillValue, 0)

            isobaric_height_ensAVG_rmse(t,ifx,:) = (/ rmseM /)


            ; fields must be re-ordered to swap isobaric and ensemble positions.
            ;[time | 161] x [fx | 15] x [ens | 21] x [isobaric | 26] x [lat | 22] x [lon | 22]

            temp_modelX     := isobaric_height_field(                    t, ifx, :, :, :, :)
            temp_analysisX0 := dim_avg_n_Wrap(isobaric_height_field(index_validation_time,   0, :,  :, :, :), 0)
            temp_analysisX  := conform(temp_modelX,              \
                                       temp_analysisX0,          \
                                       (/ 1,2,3  /) )

            rmseM := dim_rmsd_n_Wrap(temp_modelX, temp_analysisX, 0)
            replace_ieeenan(rmseM, rmseM@_FillValue, 0)

            isobaric_height_xy_rmse(t,ifx,:,:,:) = (/ rmseM /)

            print(sprinti("t%0.5i_", t) + sprinti("f%0.2i", ifx) + \
                  "_vs_" + sprinti("t%0.5i", index_validation_time) + " | " + \
                  sprinti("%0.5i_",   toint(time(t))) +   \
                  sprinti("F%0.2i",   toint(fx(ifx))) + " " +  \
                  forecast_valid_time_string(t,ifx) + " " + \
                  forecast_valid_time_string(index_validation_time,0) + " " + \
                  isobaric_height_ens000_rmse( t,ifx,{50000}) + " " + \
                  isobaric_height_ensALL_rmse(t,ifx,{50000}) + " " + \
                  isobaric_height_ensAVG_rmse(t,ifx,{50000}) )

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

         end if

      end do

   end do


   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;;; Plot Our Output  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   print("------------  Creating Diagnostic Plots  ------------")

      plot_file = "./GENS_03_ENSEMBLE__"+file_label+"__ERROR__" + \
                    scenario + "__"                   + \
                    start_date_string + "_" + working_hour + "_to_" + \
                    end_date_string + "_" + working_hour

   wks  = gsn_open_wks("pdf", plot_file) ; send graphics to PDF file

   print("OUTPUT GRAPHIC FILE: "+plot_file)


   text_label = "GENS-03 "+scenario          + " "    + \
                start_date_string + " to " + \
                end_date_string



   gsn_define_colormap(wks,"default") ; set color map for graphics

   print("Max Stdev:" +  max( (/ isobaric_height_stdev(:,:,{50000}) /) ) )
   print("Max Error:" +  max( (/ isobaric_height_ens000_rmse(:,:,{50000}) /) ) )

   res_single                   = True      ; plot mods desired
      res_single@gsnMaximize    = True      ; maximize plot in frame
      res_single@xyMarkLineMode = "Markers" ; choose which have markers
      res_single@xyMarker       = 16        ; choose type of marker
      res_single@xyMarkerSizeF  = 0.005     ; Marker size (default 0.01)
      res_single@trXMinF        = 0.0
      res_single@trXMaxF        = max( (/ isobaric_height_stdev(:,:,{50000}) /) )
      res_single@trYMinF        = 0.0
      res_single@trYMaxF        = max( (/ isobaric_height_ens000_rmse(:,:,{50000}) /) )
      res_single@gsnDraw        = False
      res_single@gsnFrame       = False

   do ifx = 1, nfx-1
      res_single@tiMainString = "500-hPa Height CI Wedge for " + \
                                  sprinti("F%0.2i",   toint(fx(ifx))) ; title
      res_single@xyMarkerColor      = ifx+1    ; Marker color starts with red@2

      print("plotting "  +res_single@tiMainString)

      plot  = gsn_csm_xy (wks,                                 \
                          isobaric_height_stdev(:,ifx,{50000}),      \
                          isobaric_height_ens000_rmse(:,ifx,{50000}), \
                          res_single)        ; create plot


      ;
      ; Adding a lower descriptive label
      ;  Justified to Bottom Right
      ;  Starting at the graphs lower right -> corner
      ;

      txres                = True
       txres@txJust = "BottomRight"
       txres@txFontHeightF = 0.02

      text = gsn_add_text(wks,plot,text_label,res_single@trXMaxF-0.5, \
                                              res_single@trYMinF+0.5 ,txres)

      draw(plot)
      frame(wks)
   end do


   ;
   ; plot all on one graph by Fx.  gsn_csm_xy sets the graph series to the
   ;     left <- most value.  Here we will need to "shuffle" the array order
   ;     using the "|" operator.
   ;

   res_multi                        = True      ; plot mods desired
      res_multi@tiMainString = "500-hPa Height CI Wedge for All Fx's" ; title
      res_multi@xyMonoMarkerSize = True
      res_multi@xyMonoMarker     = True
      res_multi@xyMarker         = 16        ; choose type of marker
      res_multi@gsnMaximize      = True      ; maximize plot in frame
      res_multi@xyMarkLineMode   = "Markers" ; choose which have markers
      res_multi@xyMarkerColors   = ispan(1,nfx-1,1)+1    ; Marker color starts with red@2
      res_multi@xyMarkerSizeF    = 0.005     ; Marker size (default 0.01)
      res_multi@trXMinF          = 0.0
      res_multi@trXMaxF          = max( (/ isobaric_height_stdev(:,:,0) /) )
      res_multi@trYMinF          = 0.0
      res_multi@trYMaxF          = max( (/ isobaric_height_ens000_rmse(:,:,0) /) )

      res_multi@gsnDraw          = False
      res_multi@gsnFrame         = False

   ind500 = ind(isobaric_height.eq.50000)
   plot   = gsn_csm_xy (wks,                                       \
                       isobaric_height_stdev(     fx | 1:nfx-1, time | :, isobaric_height | ind500), \
                       isobaric_height_ens000_rmse(fx | 1:nfx-1, time | :, isobaric_height | ind500), \
                       res_multi)        ; create plot

   ;
   ; legends take a lot of trial and error in NCL.
   ;    This is an example using the simple_legend command.
   ;

   lineres = True
      lineres@LineLengthPercent = 5    ; expressed as %, 0->100, length of line
      lineres@lgLineColors      = ispan(1,nfx-1,1)+1 ; legend line colors


   gres = True
      gres@YPosPercent = 97.               ; expressed as %, 0->100, sets position of bottom border of legend
                                        ;  when gres@Position="Bottom" (Default = 95.)
      gres@XPosPercent = 3.               ; expressed as %, 0->100, sets position of left border of legend
                                        ;  (Default = 05.)
      gres@ItemSpacePercent = 2.5          ; expressed as %, 0->100, space between legend items (Default = 5.)
      gres@LineLabelWhiteSpacePercent = 0.5 ; expressed as %, 0->100, space between line and label (Default = 3.)


   textres = True
      textres@lgLabels = sprinti("F%0.2i", toint(fx(ispan(1,nfx-1,1)))) ; labels (req)
      textres@lgLabelFontHeight = 0.015                      ; label font heights
      textres@lgLabelColors = ispan(1,nfx-1,1)+1             ; label font colors

   plot = simple_legend(wks,plot,gres,lineres,textres)

   ;
   ; Adding a lower descriptive label
   ;  Justified to Bottom Right
   ;  Starting at the graphs lower right -> corner
   ;


   txres          = True
     txres@txJust = "BottomRight"

   text = gsn_add_text(wks,plot,text_label,res_multi@trXMaxF-0.5, \
                                           res_multi@trYMinF+0.5,txres)

   draw(plot)
   frame(wks)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



   ;;;; Drop Output to File  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   ;
   ; Create Output File
   ;

   print("------------  Writing Output File  ------------")

   print("------------  Writing Output File  ------------")

   output_file = "./GENS_03_ENSEMBLE__"+file_label+"__ERROR__" + \
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

      fout->time                        = time
      fout->time                        = time

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

      fout->location_label                 = location_string
      fout->lon_center                     = lon_center
      fout->lat_center                     = lat_center
      fout->fx                             = fx
      fout->isobaric_height                = isobaric_height
      fout->elevation_of_mean_sea_level    = elevation_of_mean_sea_level
      fout->elevation_of_screen_height     = elevation_of_screen_height
      fout->elevation_of_anemometer_height = elevation_of_anemometer_height
      fout->elevation_at_ground_surface    = elevation_at_ground_surface

      fout->forecast_valid_time         = forecast_valid_time

      fout->isobaric_height_stdev       = isobaric_height_stdev
      fout->isobaric_height_xy_stdev    = isobaric_height_xy_stdev
      fout->isobaric_height_xy_rmse     = isobaric_height_xy_rmse
      fout->isobaric_height_ens000_rmse = isobaric_height_ens000_rmse
      fout->isobaric_height_ensALL_rmse = isobaric_height_ensALL_rmse
      fout->isobaric_height_ensAVG_rmse = isobaric_height_ensAVG_rmse

   delete(fout)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



end
