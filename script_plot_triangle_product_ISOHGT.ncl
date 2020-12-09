;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Program walks through the SDSMT RAID server and extracts the 500 hPa
;      fields from the GEFS ensembles and produce a basic CI triangle
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin

   ;;;;;;;Time Control;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

      ;;;; Developing the Time Coordinates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; creating the long time variable from start to end...
   ;
   start_time        = 0
   start_time@units  = "days since " + start_date_string + " " + working_hour + ":00:00"

   end_time          = 0
   end_time@units    = "days since " +  end_date_string  + " " + working_hour + ":00:00"



   time_intervals       = 6          ; hours between fx products
      time_intervals@units = "hours"

   desired_max_fx_time = 24
      desired_max_fx_time@units = "hours"

   archive_directory  = "/projects/BIG_WEATHER/wjc/GENS_Processing/arch/"
   error_directory    = "/projects/BIG_WEATHER/GENS_ERROR_RT/error_data/"
   graphics_directory = "/projects/BIG_WEATHER/GENS_ERROR_RT/ci_graphics/"
   archive_directory  = "/projects/BIG_WEATHER/GENS_ERROR_RT/triangle_archives/"


   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; Site Location
   ;

   scenario = "WRFRAP"   ; location

   ;
   ; requested isobaric height level
   ;
   isobaric_height_pull = 500*100  ; it's in Pascals
   isobaric_height_pull@units = "Pa"
   fx_time = 84
   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; Read Input File to File  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;

   ;
   ; Create Input File File with all available verified forecasts
   ;

   all_data_file = archive_directory + "gens_03_ensemble__ISOHGT__error__" + scenario + "__2015-06-01_00_to_2019-03-31_00.nc"

   ; pretend file for now that has the last 10 VERIFIED forecasts
   recent_data_file = all_data_file
   ;
   ; pretend file for now that has the last 5 VERIFIED forecasts
   new_data_file = all_data_file

   ;

   fin = addfile(all_data_file, "r")

     all_time                        = fin->time
     all_fx                          = fin->fx
     all_isobaric                    = fin->isobaric_height
     all_forecast_valid_time         = fin->forecast_valid_time

     k_all_isobaric_height_pull = ind(all_isobaric .eq. isobaric_height_pull)

     all_isobaric_height_stdev       = fin->isobaric_height_stdev(      :,:,k_all_isobaric_height_pull)
     all_isobaric_height_ens000_rmse = fin->isobaric_height_ens000_rmse(:,:,k_all_isobaric_height_pull)
     all_isobaric_height_ensALL_rmse = fin->isobaric_height_ensALL_rmse(:,:,k_all_isobaric_height_pull)

   delete(fin)

   nt_all = dimsizes(all_time)
      nt_all@description = "all time steps for all available CIs with Validation"


   ;;;  REALTIME FORECAST ERROR AND VARIANCE verified


   recent_data_file = error_directory+"GENS_03_ENSEMBLE__ISOHGT__ERROR__" + scenario + "__" + start_date_string +"_"+ working_hour + "_to_" + end_date_string +"_"+ working_hour + ".nc"


   print(recent_data_file)
   frecent = addfile(recent_data_file, "r")

     recent_time                        = frecent->time
     recent_fx                          = frecent->fx
     recent_isobaric_height             = frecent->isobaric_height
     recent_forecast_valid_time         = frecent->forecast_valid_time

      print(isobaric_height_pull)

     print(recent_isobaric_height)


     k_pull_isobaric = ind(recent_isobaric_height .eq. isobaric_height_pull)


     recent_isobaric_height_stdev       = frecent->isobaric_height_stdev(      :,:,k_pull_isobaric)
     recent_isobaric_height_ens000_rmse = frecent->isobaric_height_ens000_rmse(:,:,k_pull_isobaric)
     recent_isobaric_height_ensALL_rmse = frecent->isobaric_height_ensALL_rmse(:,:,k_pull_isobaric)

   delete(frecent)

   nt_recent = dimsizes(recent_time)
   nt_recent@description = "recent available CIs with Validation time steps"

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;; Realtime to Forecast Time for verified forecatss ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ; Create array to line up the forecast_product time to calendar time
   ;

   print("------------  Setting Time-Fx Coordinates Lookups for Forecast and Verification Times  ------------")

   rfx = dimsizes(recent_fx)

   forecast_valid_time = new((/ nt_recent, rfx /), float )
      forecast_valid_time!0             = "recent_time"
      forecast_valid_time!1             = "recent_fx"
      forecast_valid_time&recent_time   = recent_time
      forecast_valid_time&recent_fx     = recent_fx
      forecast_valid_time@long_name     = "Valid Time Coordinate for Forecast Times"
      forecast_valid_time@description   = "Valid Time Coordinate for Forecast Times"
      forecast_valid_time@standard_name = "time"
      forecast_valid_time@units         = recent_time@units
      forecast_valid_time@calendar      = "standard"

   forecast_valid_time_string = new((/ nt_recent, rfx /), string )
      forecast_valid_time_string!0           = "recent_time"
      forecast_valid_time_string!1           = "recent_fx"
      forecast_valid_time_string&recent_time = recent_time
      forecast_valid_time_string&recent_fx   = recent_fx
      forecast_valid_time_string@description = "Date Stamp Forecast Times"
      forecast_valid_time_string@long_name   = "Date Stamp Forecast Times"

   forecast_product_time_string = new((/ nt_recent, rfx /), string )
      forecast_product_time_string!0           = "recent_time"
      forecast_product_time_string!1           = "recent_fx"
      forecast_product_time_string&recent_time = recent_time
      forecast_product_time_string&recent_fx   = recent_fx
      forecast_product_time_string@description = "Date Stamp Forecast Product Times"
      forecast_product_time_string@long_name   = "Date Stamp Forecast Product Times"

   do t = 0, nt_recent-1
      do ifx = 0, rfx-1

         forecast_valid_time(t,ifx) = recent_time(t) + toint(recent_fx(ifx))

         product_time_decompose = cd_calendar(recent_time(t),             -5)
         valid_time_decompose   = cd_calendar(forecast_valid_time(t,ifx), -5)

         valid_time =   sprinti("%0.4i-", valid_time_decompose(0,0)) + \
                        sprinti("%0.2i-", valid_time_decompose(0,1)) + \
                        sprinti("%0.2i_", valid_time_decompose(0,2)) + \
                        sprinti("%0.2i",  valid_time_decompose(0,3))

         product_time = sprinti("%0.4i-",  product_time_decompose(0,0)) + \
                        sprinti("%0.2i-",  product_time_decompose(0,1)) + \
                        sprinti("%0.2i_",  product_time_decompose(0,2)) + \
                        sprinti("%0.2i_F", product_time_decompose(0,3)) + \
                        sprinti("%0.2i",   toint(recent_fx(ifx)))

         forecast_valid_time_string(t,ifx)   = valid_time
         forecast_product_time_string(t,ifx) = product_time

      end do
   end do

   ;
   print(forecast_valid_time_string(  :,{24}))
   print(forecast_product_time_string(:,{24}))

   ;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   printVarSummary(all_time)
   print(recent_time)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   plot_file = graphics_directory+"./GENS_03_TRIANGLE__500mb__" + \
                 scenario + "__"                   + \
                 start_date_string +"_"+working_hour+ "__to__"        + \
                 end_date_string +"_"+working_hour

   wks  = gsn_open_wks("png", plot_file) ; send graphics to PDF file
   gsn_define_colormap(wks,"gui_default")



   color_table_range =  toint(fspan(2, 23, nt_recent))

   text_label = "WMO 004 Grid "+ scenario

   n_plot = ( toint(desired_max_fx_time) - toint(recent_fx(1)) ) /  toint(recent_fx(1)) + 1

   plot = new(n_plot,graphic)
   plotn = 0
   do fx_time = toint(recent_fx(1)), toint(desired_max_fx_time), toint(recent_fx(1))

      ifx = ind(recent_fx .eq. fx_time)

      print("==================================================")
      print("Processing Forecast Time F" + fx_time + " array index @"+ifx)

      res_single                   = True      ; plot mods desired
         res_single@gsnMaximize    = True      ; maximize plot in frame
         res_single@xyMarkLineMode = "Markers" ; choose which have markers
         res_single@xyMarker       = 16        ; choose type of marker
         res_single@xyMarkerSizeF  = 0.005     ; Marker size (default 0.01)
         res_single@trXMinF        = 0.0
         res_single@trXMaxF        = max( (/ all_isobaric_height_stdev(:,{desired_max_fx_time}) /) )
         res_single@trYMinF        = 0.0
         res_single@trYMaxF        = max( (/ all_isobaric_height_ens000_rmse(:,{desired_max_fx_time}) /) )
         res_single@gsnDraw        = False
         res_single@gsnFrame       = False

         res_single@tiYAxisString = "Fragility (Control Ens Member RMSE)"
         res_single@tiXAxisString = "Risk (All Member's StDev)"

      ;res_single@tiMainString  = "CI Wedge for "  + end_date_string + "Z"; title

      res_single@gsnLeftString  = "Past "+sprinti("F%0.2i",   toint(all_fx({fx_time}))) +" Performance"
      res_single@gsnRightString = "500-hPa Height"

      res_single@xyMarkerColor = "grey79"   ; Marker color starts with red@2

      print("plotting " + res_single@gsnLeftString)

      ;;; Plot All Fields.

      plot(plotn)  = gsn_csm_xy (wks,                                 \
                                 all_isobaric_height_stdev(      :,{fx_time}),      \
                                 all_isobaric_height_ens000_rmse(:,{fx_time}), \
                                 res_single)        ; create plot

                          ;
                          ; Adding a lower descriptive label
                          ;  Justified to Bottom Right
                          ;  Starting at the graphs lower right -> corner
                          ;

      txres                  = True
         txres@txJust        = "TopLeft"
         txres@txFontHeightF = 0.02


     x_ULC = (res_single@trXMaxF - res_single@trXMinF) * 0.01
     y_ULC = (res_single@trYMaxF - res_single@trYMinF) * 0.01

     text = gsn_add_text(wks,plot(plotn), \
                             text_label, \
                             res_single@trXMinF + x_ULC, \
                             res_single@trYMaxF - y_ULC, \
                             txres)

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;
      ;   Inventory current fields for missing verifcation data
      ;     (these are the most current forecsts that have not had time
      ;     to be verified)

      n_forecast_dates = dimsizes(recent_isobaric_height_ens000_rmse(time | :, fx | ifx))
      marklines := new(n_forecast_dates, string)

      ind_no__verification = ind(     ismissing(recent_isobaric_height_ens000_rmse(fx | ifx, time | :)))
      ind_yes_verification = ind(.not.ismissing(recent_isobaric_height_ens000_rmse(fx | ifx, time | :)))

      if (.not.ismissing(ind_yes_verification(0)))
         do i = 0, dimsizes(ind_yes_verification)-1
            marklines(ind_yes_verification(i)) = "Markers"
            print("---- Verification Ready @ " + forecast_product_time_string(ind_yes_verification(i),{fx_time})  \
                                       +" StDev:" + recent_isobaric_height_stdev(ind_yes_verification(i),{fx_time}) \
                                       +" RMSE:" + recent_isobaric_height_ens000_rmse(ind_yes_verification(i),{fx_time})  )
         end do
      end if
      if (.not.ismissing(ind_no__verification(0)))
         do i = 0, dimsizes(ind_no__verification)-1
            marklines(ind_no__verification(i)) = "Lines"
            print("- Awaiting Verification @ " + forecast_product_time_string(ind_no__verification(i),{fx_time}) \
                                    +" StDev:" + recent_isobaric_height_stdev(ind_no__verification(i),{fx_time}) )
         end do
      end if

      line_colours = color_table_range(::-1)

      res_single2                     = True      ; plot mods desired
         res_single2@xyMarkLineModes   = marklines ; choose which have markers

         res_single2@xyMonoMarkerSize = True
         res_single2@xyMonoMarker     = True
         res_single2@xyMarker         = 16        ; choose type of marker
         res_single2@xyMarkerSizeF    = 0.015     ; Marker size (default 0.01)
         res_single2@xyMarkerColors   = line_colours   ; Marker color starts with red@2

        ; dptr
         res_single2@xyDashPattern    = "SolidLine"
         res_single2@xyLineColors     = line_colours   ; Marker color starts with red@2
         res_single2@xyLineThicknessF =  1.0


         res_single2@pmLegendDisplayMode    = "Always"   ; Display a legend.
         res_single2@pmLegendSide           = "Top"
         res_single2@pmLegendOrthogonalPosF = -0.4      ; Move into plot
         res_single2@pmLegendParallelPosF   = 1.0       ; Move to right
         res_single2@pmLegendWidthF         = 0.2       ; Decrease width
         res_single2@pmLegendHeightF        = 0.2       ; Decrease height
         res_single2@lgBoxMinorExtentF      = 0.1       ; Shorten the legend lines
         res_single2@lgLabelFontHeightF     = 0.015     ; Change the font size
         res_single2@xyExplicitLegendLabels = forecast_product_time_string(recent_time | :, recent_fx | ifx)  ; legend labels
         res_single2@lgJustification        = "TopRight"

         res_single2@gsnDraw          = False
         res_single2@gsnFrame         = False


      plot_data_sdev := (/ recent_isobaric_height_stdev(time | :, fx | ifx),  \
                           recent_isobaric_height_stdev(time | :, fx | ifx)  /)

         plot_data_sdev!0                = "ob_node"
         plot_data_sdev&ob_node          = (/ 1,2 /)
         plot_data_sdev!1                = "recent_time"
         plot_data_sdev&recent_time      = recent_time
         plot_data_sdev@description      = recent_isobaric_height_stdev@description

      plot_data_rmse := (/ recent_isobaric_height_ens000_rmse(time | :, fx | ifx) ,  \
                           recent_isobaric_height_ens000_rmse(time | :, fx | ifx)   /)

         plot_data_rmse!0                = "ob_node"
         plot_data_rmse&ob_node          = (/ 1,2 /)
         plot_data_rmse!1                = "recent_time"
         plot_data_rmse&recent_time      = recent_time
         plot_data_rmse@description      = recent_isobaric_height_ens000_rmse@description

      plot_data_sdev := plot_data_sdev(recent_time | :, ob_node | : )
      plot_data_rmse := plot_data_rmse(recent_time | :, ob_node | : )


      if (.not.ismissing(ind_no__verification(0)))
         plot_data_rmse(ind_no__verification,0) = -999999.0
         plot_data_rmse(ind_no__verification,1) =  999999.0
      end if


      plot2  = gsn_xy (wks, plot_data_sdev, \
                            plot_data_rmse, \
                            res_single2)

      overlay(plot(plotn),plot2)



      ; draw(plot(plotn))



      delete(ind_no__verification)
      delete(ind_yes_verification)
      plotn = plotn + 1
   end do

   panel_res                    = True
   panel_res@gsnPanelMainString = "GFS Ensemble CI Wedge for "  + end_date_string+ " "+ working_hour + "Z"

   gsn_panel(wks,plot,(/2,2/),panel_res)

   print(n_plot)

delete(res_single2)
delete(res_single)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  OK SARAH!  THIS PART ISN'T DONE YET!
;;;




print(" get get clock times top use ")

real_world_clock_times = forecast_valid_time(nt_recent-1,1:4)


fx_hour_for_valid_time = new((/ nt_recent,4 /), integer)
   fx_hour_for_valid_time!0 = "forecast_product"
   fx_hour_for_valid_time&forecast_product = recent_time
   fx_hour_for_valid_time!1 = "valid_forecast_time"
   fx_hour_for_valid_time&valid_forecast_time = real_world_clock_times

printVarSummary(fx_hour_for_valid_time)

label_strings_for_plots = new((/ nt_recent,4 /), string)
   label_strings_for_plots!0 = "forecast_product"
   label_strings_for_plots&forecast_product = recent_time
   label_strings_for_plots!1 = "valid_forecast_time"
   label_strings_for_plots&valid_forecast_time = real_world_clock_times



;print(fx_hour_for_valid_time)



print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")

plotn = 0


do fx_time = 1, 4, 1


   print("==================================================")
   print("Processing Forecast for " + forecast_valid_time_string(nt_recent-1,fx_time) + "Z array index @"+ifx)
   print(" "+real_world_clock_times(fx_time-1)+" "+forecast_valid_time_string(nt_recent-1,fx_time))


   rmse_values_for_line_dots = new( nt_recent, float)
   stdv_values_for_line_dots = new( nt_recent, float)



   do r = 0, nt_recent-1
      fx_hour_for_valid_time(r,fx_time-1) = ind(forecast_valid_time(r,:) .eq. real_world_clock_times(fx_time-1))
      label_strings_for_plots(r,fx_time-1) =  (/ forecast_product_time_string(r,fx_hour_for_valid_time(r,fx_time-1)) /)

      rmse_values_for_line_dots(r) = recent_isobaric_height_ens000_rmse(time | r, fx | fx_hour_for_valid_time(r,fx_time-1))
      stdv_values_for_line_dots(r) = recent_isobaric_height_stdev(      time | r, fx | fx_hour_for_valid_time(r,fx_time-1))

      print("    " + forecast_valid_time_string(r,fx_hour_for_valid_time(r,fx_time-1))  + " "  \
                   + label_strings_for_plots(r,fx_time-1)       \
                   + " StD="  + stdv_values_for_line_dots(r)    \
                   + " RMSE=" +  rmse_values_for_line_dots(r)   )


   end do




   res_single                   = True      ; plot mods desired
      res_single@gsnMaximize    = True      ; maximize plot in frame
      res_single@xyMarkLineMode = "Markers" ; choose which have markers
      res_single@xyMarker       = 16        ; choose type of marker
      res_single@xyMarkerSizeF  = 0.005     ; Marker size (default 0.01)
      res_single@trXMinF        = 0.0
      res_single@trXMaxF        = max( (/ all_isobaric_height_stdev(:,:) /) )
      res_single@trYMinF        = 0.0
      res_single@trYMaxF        = max( (/ all_isobaric_height_ens000_rmse(:,:) /) )
      res_single@gsnDraw        = False
      res_single@gsnFrame       = False

      res_single@tiYAxisString = "Fragility (Control Ens Member RMSE)"
      res_single@tiXAxisString = "Risk (All Member's StDev)"


   ;res_single@tiMainString  = "CI Wedge for "  + end_date_string + "Z"; title

   res_single@gsnLeftString  = "Past "+forecast_valid_time_string(nt_recent-1,fx_time) + " Performance"
   res_single@gsnRightString = "500-hPa Height"

   res_single@xyMarkerColor = "grey79"   ; Marker color starts with red@2

   print("plotting " + res_single@gsnLeftString)

   ;;; Plot All Fields.

   plot(plotn)  = gsn_csm_xy (wks,                                 \
                              ndtooned(all_isobaric_height_stdev(      :,{6:84:06})),      \
                              ndtooned(all_isobaric_height_ens000_rmse(:,{6:84:06})), \
                              res_single)        ; create plot

                       ;
                       ; Adding a lower descriptive label
                       ;  Justified to Bottom Right
                       ;  Starting at the graphs lower right -> corner
                       ;

   txres                  = True
      txres@txJust        = "TopLeft"
      txres@txFontHeightF = 0.02


    x_ULC = (res_single@trXMaxF - res_single@trXMinF) * 0.01
    y_ULC = (res_single@trYMaxF - res_single@trYMinF) * 0.01

    text = gsn_add_text(wks,plot(plotn), \
                            text_label, \
                            res_single@trXMinF + x_ULC, \
                            res_single@trYMaxF - y_ULC, \
                            txres)

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;   Inventory current fields for missing verifcation data
   ;     (these are the most current forecsts that have not had time
   ;     to be verified)

   n_forecast_dates = dimsizes(recent_isobaric_height_ens000_rmse(time | :, fx | fx_time-1))

   marklines := new(n_forecast_dates, string)

   ind_no__verification = ind(     ismissing(rmse_values_for_line_dots))
   ind_yes_verification = ind(.not.ismissing(rmse_values_for_line_dots))



   if (.not.ismissing(ind_yes_verification(0)))
      do i = 0, dimsizes(ind_yes_verification)-1
         marklines(ind_yes_verification(i)) = "Markers"
         print("---- Verification Ready @ " + label_strings_for_plots(forecast_product | i, valid_forecast_time | fx_time-1)   \
                                 +" StDev:" + stdv_values_for_line_dots(ind_yes_verification(i)) \
                                 +" RMSE:"  + rmse_values_for_line_dots(ind_yes_verification(i))  )
      end do
   end if
   if (.not.ismissing(ind_no__verification(0)))
      do i = 0, dimsizes(ind_no__verification)-1
         marklines(ind_no__verification(i)) = "Lines"
         print("- Awaiting Verification @ " + label_strings_for_plots(forecast_product | i, valid_forecast_time | fx_time-1) \
                                 +" StDev:" + stdv_values_for_line_dots(ind_no__verification(i)))
      end do
   end if

   line_colours = color_table_range(::-1)

   res_single2                     = True      ; plot mods desired
      res_single2@xyMarkLineModes   = marklines ; choose which have markers

      res_single2@xyMonoMarkerSize = True
      res_single2@xyMonoMarker     = True
      res_single2@xyMarker         = 16        ; choose type of marker
      res_single2@xyMarkerSizeF    = 0.0075     ; Marker size (default 0.01)
      res_single2@xyMarkerColors   = line_colours   ; Marker color starts with red@2

     ; dptr
      res_single2@xyDashPattern    = "SolidLine"
      res_single2@xyLineColors     = line_colours   ; Marker color starts with red@2
      res_single2@xyLineThicknessF =  1.0

      res_single2@pmLegendDisplayMode    = "Always"   ; Display a legend.
      res_single2@pmLegendOrthogonalPosF = -0.515      ; Move into plot
      res_single2@pmLegendParallelPosF   = 1.0       ; Move to right
      res_single2@pmLegendWidthF         = 0.2       ; Decrease width
      res_single2@pmLegendHeightF        = 0.2       ; Decrease height
      res_single2@lgBoxMinorExtentF      = 0.1       ; Shorten the legend lines
      res_single2@lgLabelFontHeightF     = 0.015     ; Change the font size
      res_single2@xyExplicitLegendLabels = label_strings_for_plots(forecast_product | :, valid_forecast_time | fx_time-1)  ; legend labels
      res_single2@lgJustification        = "TopRight"

      res_single2@gsnDraw          = False
      res_single2@gsnFrame         = False



   plot_data_sdev := (/ stdv_values_for_line_dots,  \
                        stdv_values_for_line_dots  /)

      plot_data_sdev!0                = "ob_node"
      plot_data_sdev&ob_node          = (/ 1,2 /)
      plot_data_sdev!1                = "recent_time"
      plot_data_sdev&recent_time      = recent_time
      plot_data_sdev@description      = recent_isobaric_height_stdev@description

   plot_data_rmse := (/ rmse_values_for_line_dots,  \
                        rmse_values_for_line_dots   /)

      plot_data_rmse!0                = "ob_node"
      plot_data_rmse&ob_node          = (/ 1,2 /)
      plot_data_rmse!1                = "recent_time"
      plot_data_rmse&recent_time      = recent_time
      plot_data_rmse@description      = recent_isobaric_height_ens000_rmse@description

   plot_data_sdev := plot_data_sdev(recent_time | :, ob_node | : )
   plot_data_rmse := plot_data_rmse(recent_time | :, ob_node | : )


   if (.not.ismissing(ind_no__verification(0)))
      plot_data_rmse(ind_no__verification,0) = -999999.0
      plot_data_rmse(ind_no__verification,1) =  999999.0
   end if


   plot2  = gsn_xy (wks, plot_data_sdev, \
                         plot_data_rmse, \
                         res_single2)

   overlay(plot(plotn),plot2)



   ; draw(plot(plotn))



   delete(ind_no__verification)
   delete(ind_yes_verification)
   plotn = plotn + 1
end do

panel_res                    = True
panel_res@gsnPanelMainString = "GFS Ensemble CI Wedge for "  + end_date_string + " "+ working_hour + "Z"

gsn_panel(wks,plot,(/2,2/),panel_res)

print(n_plot)

delete(wks)

system ("scp " + plot_file + ".000001.png  wjc@kyrill.ias.sdsmt.edu:/var/www/html/firemet/wrf_rap/current_ci_triangle_by_FxTime.png")
system ("scp " + plot_file + ".000002.png  wjc@kyrill.ias.sdsmt.edu:/var/www/html/firemet/wrf_rap/current_ci_triangle_by_RealTime.png")

system("ls -altr " + plot_file + ".000001.png  /var/www/html/firemet/wrf_rap/current_ci_triangle_by_FxTime.png")
system("ls -altr " + plot_file + ".000002.png  /var/www/html/firemet/wrf_rap/current_ci_triangle_by_RealTime.png")




end
