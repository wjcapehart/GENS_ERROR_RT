
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

   print("Start = "+start_date_string)
   print("  End = "+end_date_string)
   print(" Site = "+scenario)


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
      copy_VarAtts(f->Pressure_reduced_to_MSL_msl_ens, mean_sea_level_pressure_field)
      delete(mean_sea_level_pressure_field@coordinates)
      mean_sea_level_pressure_field@_FillValue    = default_fillvalue(typeof(mean_sea_level_pressure_field))
      mean_sea_level_pressure_field@missing_value = mean_sea_level_pressure_field@_FillValue
      mean_sea_level_pressure_field@description   = "Surface Pressure Reduced to Mean Sea Level (all members)"
      mean_sea_level_pressure_field@long_name     = mean_sea_level_pressure_field@description
      mean_sea_level_pressure_field@standard_name = "air_pressure_at_sea_level"
      mean_sea_level_pressure_field(:, :, :, :, :, :) = mean_sea_level_pressure_field@_FillValue


      mean_6hr_upward_northward_momentum_flux_surface_field =  mean_sea_level_pressure_field
         copy_VarAtts(f->$"Momentum_flux_v-component_surface_6_Hour_Average_ens"$, mean_6hr_upward_northward_momentum_flux_surface_field)
         mean_6hr_upward_northward_momentum_flux_surface_field!3             = "elevation_at_ground_surface"
         mean_6hr_upward_northward_momentum_flux_surface_field&elevation_at_ground_surface = elevation_at_ground_surface
         mean_6hr_upward_northward_momentum_flux_surface_field@description   = "6-hr Mean Upward Northward Momentum Flux (all members)"
         mean_6hr_upward_northward_momentum_flux_surface_field@long_name     = mean_6hr_upward_northward_momentum_flux_surface_field@description
         mean_6hr_upward_northward_momentum_flux_surface_field@standard_name = "upward_northward_momentum_flux_in_air"
         delete(mean_6hr_upward_northward_momentum_flux_surface_field@standard_name)
         mean_6hr_upward_northward_momentum_flux_surface_field@units         = "Pa"
         delete(mean_6hr_upward_northward_momentum_flux_surface_field@coordinates)
         mean_6hr_upward_northward_momentum_flux_surface_field@_FillValue    = default_fillvalue(typeof(mean_6hr_upward_northward_momentum_flux_surface_field))
         mean_6hr_upward_northward_momentum_flux_surface_field@missing_value = mean_6hr_upward_northward_momentum_flux_surface_field@_FillValue
         mean_6hr_upward_northward_momentum_flux_surface_field@comment = "no value for the fx = 0 hr (analysis) time"

      delete(mean_sea_level_pressure_field)
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


         if ( isfilevar(f,"Momentum_flux_v-component_surface_6_Hour_Average_ens") ) then
            inarr =  f->$"Momentum_flux_v-component_surface_6_Hour_Average_ens"$
            replace_ieeenan(inarr, inarr@_FillValue, 0)
            inarr!0 = "thredds_fx"
            inarr!1 = "thredds_ens"
            thredds_fx  = inarr&thredds_fx
            thredds_ens = inarr&thredds_ens
            mean_6hr_upward_northward_momentum_flux_surface_field( t, {thredds_fx}, {thredds_ens}, 0, :, :) = (/ inarr({thredds_fx},{thredds_ens},:,:) /)
            if (dimsizes(thredds_fx).ne.(dimsizes(fx)-1)) then
               print("      !!!!  Error in "+fx_time+" Fx size for Momentum_flux_v-component_surface_6_Hour_Average_ens")
            end if
            if (dimsizes(thredds_ens).ne.dimsizes(ens)) then
               print("      !!!!  Error in "+fx_time+" Ens size for Momentum_flux_v-component_surface_6_Hour_Average_ens")
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

   mean_6hr_upward_northward_momentum_flux_surface_xy_stdev = dim_stddev_n_Wrap(mean_6hr_upward_northward_momentum_flux_surface_field, 2)
   mean_6hr_upward_northward_momentum_flux_surface_xy_stdev@cell_method   = "ens:standard_deviation"
   mean_6hr_upward_northward_momentum_flux_surface_xy_stdev@long_name     = "6-hr Mean Upward Northward Momentum Flux StDev by Lat-Lon"
   mean_6hr_upward_northward_momentum_flux_surface_xy_stdev@description   = mean_6hr_upward_northward_momentum_flux_surface_xy_stdev@long_name


   ; Average stdevs across latitudes and longitudes
   ;  input indexes            : [time] x [fx] x [isobaric] x [lat] x [lon]
   ;  remaining output indexes : [time] x [fx] x [isobaric]

   print("------------  Calculating Spatially-Averaged Standard Deviation Fields  ------------")


      mean_6hr_upward_northward_momentum_flux_surface_stdev = dim_avg_n_Wrap(mean_6hr_upward_northward_momentum_flux_surface_xy_stdev, (/ 3, 4 /))
      mean_6hr_upward_northward_momentum_flux_surface_stdev@long_name     = "6-hr Mean Upward Northward Momentum Flux StDev"
      mean_6hr_upward_northward_momentum_flux_surface_stdev@description   = "6-hr Mean Upward Northward Momentum Flux StDev"
      mean_6hr_upward_northward_momentum_flux_surface_stdev@standard_name = "upward_northward_momentum_flux_in_air"
      mean_6hr_upward_northward_momentum_flux_surface_stdev@cell_method   = "ens:standard_deviation lon:mean lat:mean"

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





   ;;;; Drop Output to File  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   ;
   ; Create Output File
   ;

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

      fout->mean_6hr_upward_northward_momentum_flux_surface_xy_stdev    = mean_6hr_upward_northward_momentum_flux_surface_xy_stdev
      fout->mean_6hr_upward_northward_momentum_flux_surface_stdev       = mean_6hr_upward_northward_momentum_flux_surface_stdev

   delete(fout)

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



end
