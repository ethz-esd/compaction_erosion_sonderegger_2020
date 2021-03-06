#install.packages('rgdal')
#install.packages('raster')
#install.packages('readxl')
library(rgdal)
library(raster)
library(readxl)


# Set working directory
#setwd('/home/sothomas/R_code/soil')
setwd('C:/Users/Sonderegger/Documents/Sync/R_code/soil')

start.time = Sys.time()


##############################

# CHOOSE TIME HORIZON IN YEARS
time_horizon = 50

# CHOOSE CONVERSION FACTOR FROM EROSION TO YIELD LOSS (GLOBAL PRESET IS 0.02)
conversion_factor = 0.02

# Load rasters
r_w = raster('./data/prepared/mx_ts_yearly_10km_weighted_median.tif')
r = raster('./data/prepared/mx_ts_yearly_10km_median.tif')
r_w[r_w == 0] = NA
mx_ts = cover(r_w, r)

r_w = raster('./data/prepared/mx_ms_yearly_10km_weighted_median.tif')
r = raster('./data/prepared/mx_ms_yearly_10km_median.tif')
r_w[r_w == 0] = NA
mx_ms = cover(r_w, r)

f = (0.272/400*time_horizon) / (0.326/40)  # bottom / mid
f
mx_bs = mx_ms * f

# Load inventory results

df = read_excel('./data/prepared/topcrops_results.xlsx', sheet='Inventory', col_names=TRUE)
df


###########

# Functions

func_cleanup_raster = function(raster, raster_reference) {
  raster_clean = crop(raster, extent(raster_reference))
  raster_clean[is.na(raster_reference)] = NA
  return(raster_clean)
}


################################################

# Calculation of actual and potential production

################################################

# Actual crop production area

# Crop cycles
cropland_f = raster('./data/EarthStat/CroplandPastureArea2000_Geotiff/Cropland2000_5m.tif')
cropland_f = func_cleanup_raster(cropland_f, mx_ts)

wheat_farea = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/wheat/wheat_HarvestedAreaFraction.tif')
wheat_farea = func_cleanup_raster(wheat_farea, mx_ts)
wheat_cropcycles = wheat_farea / cropland_f
wheat_cropcycles[wheat_cropcycles < 1] = 1

maize_farea = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/maize/maize_HarvestedAreaFraction.tif')
maize_farea = func_cleanup_raster(maize_farea, mx_ts)
maize_cropcycles = maize_farea / cropland_f
maize_cropcycles[maize_cropcycles < 1] = 1

soybean_farea = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/soybean/soybean_HarvestedAreaFraction.tif')
soybean_farea = func_cleanup_raster(soybean_farea, mx_ts)
soybean_cropcycles = soybean_farea / cropland_f
soybean_cropcycles[soybean_cropcycles < 1] = 1

# Area harvested
wheat_area = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/wheat/wheat_HarvestedAreaHectares.tif')
wheat_area = func_cleanup_raster(wheat_area, mx_ts)

maize_area = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/maize/maize_HarvestedAreaHectares.tif')
maize_area = func_cleanup_raster(maize_area, mx_ts)

soybean_area = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/soybean/soybean_HarvestedAreaHectares.tif')
soybean_area = func_cleanup_raster(soybean_area, mx_ts)

# Actual crop area

wheat_actarea = wheat_area / wheat_cropcycles
#writeRaster(wheat_actarea, paste0('./data/calculated/wheat_croparea_actual.tif'), format = 'GTiff', overwrite = TRUE)

maize_actarea = maize_area / maize_cropcycles
#writeRaster(maize_actarea, paste0('./data/calculated/maize_croparea_actual.tif'), format = 'GTiff', overwrite = TRUE)

soybean_actarea = soybean_area / soybean_cropcycles
#writeRaster(soybean_actarea, paste0('./data/calculated/soybean_croparea_actual.tif'), format = 'GTiff', overwrite = TRUE)

###############################

# Actual production in one year
# actual yield [t/ha/crop-cycle] * area harvested [ha] * crop cycles per year [1/yr] = t / yr (per cell)

# Actual yield
wheat_yield = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/wheat/wheat_YieldPerHectare.tif')
wheat_yield = func_cleanup_raster(wheat_yield, mx_ts)

maize_yield = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/maize/maize_YieldPerHectare.tif')
maize_yield = func_cleanup_raster(maize_yield, mx_ts)

soybean_yield = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/soybean/soybean_YieldPerHectare.tif')
soybean_yield = func_cleanup_raster(soybean_yield, mx_ts)

# Actual production
wheat_prod = wheat_yield * wheat_actarea * df[['crop_cycles']][1]
maize_prod = maize_yield * maize_actarea * df[['crop_cycles']][4]
soybean_prod = soybean_yield * soybean_actarea * df[['crop_cycles']][7]

wheat_prod_sum = cellStats(wheat_prod, sum)
maize_prod_sum = cellStats(maize_prod, sum)
soybean_prod_sum = cellStats(soybean_prod, sum)

##################################

# Potential production in one year
# potential yield [t/ha/crop-cycle] * crop area [ha] * crop cycles per year [crop-cycles/yr] = t / yr

# Potential yield
wheat_potyield = raster('./data/EarthStat/YieldGapMajorCrops_Geotiff/wheat_yieldgap_geotiff/wheat_yieldpotential.tif')
wheat_potyield = func_cleanup_raster(wheat_potyield, mx_ts)

maize_potyield = raster('./data/EarthStat/YieldGapMajorCrops_Geotiff/maize_yieldgap_geotiff/maize_yieldpotential.tif')
maize_potyield = func_cleanup_raster(maize_potyield, mx_ts)

soybean_potyield = raster('./data/EarthStat/YieldGapMajorCrops_Geotiff/soybean_yieldgap_geotiff/soybean_yieldpotential.tif')
soybean_potyield = func_cleanup_raster(soybean_potyield, mx_ts)

# Potential production
wheat_potprod = wheat_potyield * wheat_actarea * df[['crop_cycles']][1]
maize_potprod = maize_potyield * maize_actarea * df[['crop_cycles']][4]
soybean_potprod = soybean_potyield * soybean_actarea * df[['crop_cycles']][7]

wheat_potprod_sum = cellStats(wheat_potprod, sum)
maize_potprod_sum = cellStats(maize_potprod, sum)
soybean_potprod_sum = cellStats(soybean_potprod, sum)

# RESULTS (Table S4)

a = c(cellStats(wheat_actarea, sum) / 1e6, cellStats(maize_actarea, sum) / 1e6, cellStats(soybean_actarea, sum) / 1e6)
b = c(cellStats(wheat_prod, sum) / cellStats(wheat_actarea, sum) / df[['crop_cycles']][1],
      cellStats(maize_prod, sum) / cellStats(maize_actarea, sum) / df[['crop_cycles']][4],
      cellStats(soybean_prod, sum) / cellStats(soybean_actarea, sum) / df[['crop_cycles']][7])
c = c(cellStats(wheat_potprod, sum) / cellStats(wheat_actarea, sum) / df[['crop_cycles']][1],
      cellStats(maize_potprod, sum) / cellStats(maize_actarea, sum) / df[['crop_cycles']][4],
      cellStats(soybean_potprod, sum) / cellStats(soybean_actarea, sum) / df[['crop_cycles']][7])
d = c(df[['crop_cycles']][1], df[['crop_cycles']][4], df[['crop_cycles']][7])
e = c(cellStats(wheat_prod, sum) / 1e6, cellStats(maize_prod, sum) / 1e6, cellStats(soybean_prod, sum) / 1e6)
f = c(wheat_potprod_sum / 1e6, maize_potprod_sum / 1e6, soybean_potprod_sum / 1e6)

ts4 = data.frame(a, b, c, d, e, f)
ts4


###################################

# Calculation of compaction impacts

###################################

# Compaction losses per ha-yr

# Conventional
# Compaction stress [tonkm / ha-yr] * CFs [% yield loss ha-yr / tonkm] = % yield loss * ha-yr / ha-yr

# Wheat
yl_wheat_s = df[['comp_top']][1] * mx_ts + df[['comp_mid']][1] * mx_ms + df[['comp_bottom']][1] * mx_bs
yl_wheat_m = df[['comp_top']][2] * mx_ts + df[['comp_mid']][2] * mx_ms + df[['comp_bottom']][2] * mx_bs 
yl_wheat_l = df[['comp_top']][3] * mx_ts + df[['comp_mid']][3] * mx_ms + df[['comp_bottom']][3] * mx_bs

# Maize
yl_maize_s = df[['comp_top']][4] * mx_ts + df[['comp_mid']][4] * mx_ms + df[['comp_bottom']][4] * mx_bs
yl_maize_m = df[['comp_top']][5] * mx_ts + df[['comp_mid']][5] * mx_ms + df[['comp_bottom']][5] * mx_bs
yl_maize_l = df[['comp_top']][6] * mx_ts + df[['comp_mid']][6] * mx_ms + df[['comp_bottom']][6] * mx_bs

# Soybean
yl_soybean_s = df[['comp_top']][7] * mx_ts + df[['comp_mid']][7] * mx_ms + df[['comp_bottom']][7] * mx_bs
yl_soybean_m = df[['comp_top']][8] * mx_ts + df[['comp_mid']][8] * mx_ms + df[['comp_bottom']][8] * mx_bs
yl_soybean_l = df[['comp_top']][9] * mx_ts + df[['comp_mid']][9] * mx_ms + df[['comp_bottom']][9] * mx_bs


# Reduced tillage

# Wheat
yl_wheat_rt_s = df[['comp_top']][10] * mx_ts + df[['comp_mid']][10] * mx_ms + df[['comp_bottom']][10] * mx_bs
yl_wheat_rt_m = df[['comp_top']][11] * mx_ts + df[['comp_mid']][11] * mx_ms + df[['comp_bottom']][11] * mx_bs 
yl_wheat_rt_l = df[['comp_top']][12] * mx_ts + df[['comp_mid']][12] * mx_ms + df[['comp_bottom']][12] * mx_bs

# Maize
yl_maize_rt_s = df[['comp_top']][13] * mx_ts + df[['comp_mid']][13] * mx_ms + df[['comp_bottom']][13] * mx_bs
yl_maize_rt_m = df[['comp_top']][14] * mx_ts + df[['comp_mid']][14] * mx_ms + df[['comp_bottom']][14] * mx_bs
yl_maize_rt_l = df[['comp_top']][15] * mx_ts + df[['comp_mid']][15] * mx_ms + df[['comp_bottom']][15] * mx_bs

# Soybean
yl_soybean_rt_s = df[['comp_top']][16] * mx_ts + df[['comp_mid']][16] * mx_ms + df[['comp_bottom']][16] * mx_bs
yl_soybean_rt_m = df[['comp_top']][17] * mx_ts + df[['comp_mid']][17] * mx_ms + df[['comp_bottom']][17] * mx_bs
yl_soybean_rt_l = df[['comp_top']][18] * mx_ts + df[['comp_mid']][18] * mx_ms + df[['comp_bottom']][18] * mx_bs


# No tillage

# Wheat
yl_wheat_nt_s = df[['comp_top']][19] * mx_ts + df[['comp_mid']][19] * mx_ms + df[['comp_bottom']][19] * mx_bs
yl_wheat_nt_m = df[['comp_top']][20] * mx_ts + df[['comp_mid']][20] * mx_ms + df[['comp_bottom']][20] * mx_bs 
yl_wheat_nt_l = df[['comp_top']][21] * mx_ts + df[['comp_mid']][21] * mx_ms + df[['comp_bottom']][21] * mx_bs

# Maize
yl_maize_nt_s = df[['comp_top']][22] * mx_ts + df[['comp_mid']][22] * mx_ms + df[['comp_bottom']][22] * mx_bs
yl_maize_nt_m = df[['comp_top']][23] * mx_ts + df[['comp_mid']][23] * mx_ms + df[['comp_bottom']][23] * mx_bs
yl_maize_nt_l = df[['comp_top']][24] * mx_ts + df[['comp_mid']][24] * mx_ms + df[['comp_bottom']][24] * mx_bs

# Soybean
yl_soybean_nt_s = df[['comp_top']][25] * mx_ts + df[['comp_mid']][25] * mx_ms + df[['comp_bottom']][25] * mx_bs
yl_soybean_nt_m = df[['comp_top']][26] * mx_ts + df[['comp_mid']][26] * mx_ms + df[['comp_bottom']][26] * mx_bs
yl_soybean_nt_l = df[['comp_top']][27] * mx_ts + df[['comp_mid']][27] * mx_ms + df[['comp_bottom']][27] * mx_bs


###################

# Compaction losses

# Compaction losses per ha-yr * potential yield per crop cycle * area * cropy cycles per year
# = Compaction losses per ha-yr * potential production
# %_yield_loss*ha-yr/ha-yr * t/ha/cc * ha  * cc/yr = t / yr

# Conventional

# Wheat
wheat_potprod_sum = cellStats(wheat_potprod, sum)

wheat_s_losses = yl_wheat_s / 100 * wheat_potprod
wheat_s_totloss = cellStats(wheat_s_losses, sum)
wheat_s_percloss = cellStats(wheat_s_losses, sum) / wheat_potprod_sum * 100

wheat_m_losses = yl_wheat_m / 100 * wheat_potprod
wheat_m_totloss = cellStats(wheat_m_losses, sum)
wheat_m_percloss = cellStats(wheat_m_losses, sum) / wheat_potprod_sum * 100

wheat_l_losses = yl_wheat_l / 100 * wheat_potprod
wheat_l_totloss = cellStats(wheat_l_losses, sum)
wheat_l_percloss = cellStats(wheat_l_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_potprod_sum = cellStats(maize_potprod, sum)

maize_s_losses = yl_maize_s / 100 * maize_potprod
maize_s_totloss = cellStats(maize_s_losses, sum)
maize_s_percloss = cellStats(maize_s_losses, sum) / maize_potprod_sum * 100

maize_m_losses = yl_maize_m / 100 * maize_potprod
maize_m_totloss = cellStats(maize_m_losses, sum)
maize_m_percloss = cellStats(maize_m_losses, sum) / maize_potprod_sum * 100

maize_l_losses = yl_maize_l / 100 * maize_potprod
maize_l_totloss = cellStats(maize_l_losses, sum)
maize_l_percloss = cellStats(maize_l_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_potprod_sum = cellStats(soybean_potprod, sum)

soybean_s_losses = yl_soybean_s / 100 * soybean_potprod
soybean_s_totloss = cellStats(soybean_s_losses, sum)
soybean_s_percloss = cellStats(soybean_s_losses, sum) / soybean_potprod_sum * 100

soybean_m_losses = yl_soybean_m / 100 * soybean_potprod
soybean_m_totloss = cellStats(soybean_m_losses, sum)
soybean_m_percloss = cellStats(soybean_m_losses, sum) / soybean_potprod_sum * 100

soybean_l_losses = yl_soybean_l / 100 * soybean_potprod
soybean_l_totloss = cellStats(soybean_l_losses, sum)
soybean_l_percloss = cellStats(soybean_l_losses, sum) / soybean_potprod_sum * 100

# Reduced tillage

# Wheat
wheat_potprod_sum = cellStats(wheat_potprod, sum)

wheat_rt_s_losses = yl_wheat_rt_s / 100 * wheat_potprod
wheat_rt_s_totloss = cellStats(wheat_rt_s_losses, sum)
wheat_rt_s_percloss = cellStats(wheat_rt_s_losses, sum) / wheat_potprod_sum * 100

wheat_rt_m_losses = yl_wheat_rt_m / 100 * wheat_potprod
wheat_rt_m_totloss = cellStats(wheat_rt_m_losses, sum)
wheat_rt_m_percloss = cellStats(wheat_rt_m_losses, sum) / wheat_potprod_sum * 100

wheat_rt_l_losses = yl_wheat_rt_l / 100 * wheat_potprod
wheat_rt_l_totloss = cellStats(wheat_rt_l_losses, sum)
wheat_rt_l_percloss = cellStats(wheat_rt_l_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_potprod_sum = cellStats(maize_potprod, sum)

maize_rt_s_losses = yl_maize_rt_s / 100 * maize_potprod
maize_rt_s_totloss = cellStats(maize_rt_s_losses, sum)
maize_rt_s_percloss = cellStats(maize_rt_s_losses, sum) / maize_potprod_sum * 100

maize_rt_m_losses = yl_maize_rt_m / 100 * maize_potprod
maize_rt_m_totloss = cellStats(maize_rt_m_losses, sum)
maize_rt_m_percloss = cellStats(maize_rt_m_losses, sum) / maize_potprod_sum * 100

maize_rt_l_losses = yl_maize_rt_l / 100 * maize_potprod
maize_rt_l_totloss = cellStats(maize_rt_l_losses, sum)
maize_rt_l_percloss = cellStats(maize_rt_l_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_potprod_sum = cellStats(soybean_potprod, sum)

soybean_rt_s_losses = yl_soybean_rt_s / 100 * soybean_potprod
soybean_rt_s_totloss = cellStats(soybean_rt_s_losses, sum)
soybean_rt_s_percloss = cellStats(soybean_rt_s_losses, sum) / soybean_potprod_sum * 100

soybean_rt_m_losses = yl_soybean_rt_m / 100 * soybean_potprod
soybean_rt_m_totloss = cellStats(soybean_rt_m_losses, sum)
soybean_rt_m_percloss = cellStats(soybean_rt_m_losses, sum) / soybean_potprod_sum * 100

soybean_rt_l_losses = yl_soybean_rt_l / 100 * soybean_potprod
soybean_rt_l_totloss = cellStats(soybean_rt_l_losses, sum)
soybean_rt_l_percloss = cellStats(soybean_rt_l_losses, sum) / soybean_potprod_sum * 100

# No tillage

# Wheat
wheat_potprod_sum = cellStats(wheat_potprod, sum)

wheat_nt_s_losses = yl_wheat_nt_s / 100 * wheat_potprod
wheat_nt_s_totloss = cellStats(wheat_nt_s_losses, sum)
wheat_nt_s_percloss = cellStats(wheat_nt_s_losses, sum) / wheat_potprod_sum * 100

wheat_nt_m_losses = yl_wheat_nt_m / 100 * wheat_potprod
wheat_nt_m_totloss = cellStats(wheat_nt_m_losses, sum)
wheat_nt_m_percloss = cellStats(wheat_nt_m_losses, sum) / wheat_potprod_sum * 100

wheat_nt_l_losses = yl_wheat_nt_l / 100 * wheat_potprod
wheat_nt_l_totloss = cellStats(wheat_nt_l_losses, sum)
wheat_nt_l_percloss = cellStats(wheat_nt_l_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_potprod_sum = cellStats(maize_potprod, sum)

maize_nt_s_losses = yl_maize_nt_s / 100 * maize_potprod
maize_nt_s_totloss = cellStats(maize_nt_s_losses, sum)
maize_nt_s_percloss = cellStats(maize_nt_s_losses, sum) / maize_potprod_sum * 100

maize_nt_m_losses = yl_maize_nt_m / 100 * maize_potprod
maize_nt_m_totloss = cellStats(maize_nt_m_losses, sum)
maize_nt_m_percloss = cellStats(maize_nt_m_losses, sum) / maize_potprod_sum * 100

maize_nt_l_losses = yl_maize_nt_l / 100 * maize_potprod
maize_nt_l_totloss = cellStats(maize_nt_l_losses, sum)
maize_nt_l_percloss = cellStats(maize_nt_l_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_potprod_sum = cellStats(soybean_potprod, sum)

soybean_nt_s_losses = yl_soybean_nt_s / 100 * soybean_potprod
soybean_nt_s_totloss = cellStats(soybean_nt_s_losses, sum)
soybean_nt_s_percloss = cellStats(soybean_nt_s_losses, sum) / soybean_potprod_sum * 100

soybean_nt_m_losses = yl_soybean_nt_m / 100 * soybean_potprod
soybean_nt_m_totloss = cellStats(soybean_nt_m_losses, sum)
soybean_nt_m_percloss = cellStats(soybean_nt_m_losses, sum) / soybean_potprod_sum * 100

soybean_nt_l_losses = yl_soybean_nt_l / 100 * soybean_potprod
soybean_nt_l_totloss = cellStats(soybean_nt_l_losses, sum)
soybean_nt_l_percloss = cellStats(soybean_nt_l_losses, sum) / soybean_potprod_sum * 100


# Collect compaction results
act_prod = c(wheat_prod_sum, wheat_prod_sum, wheat_prod_sum,
             maize_prod_sum, maize_prod_sum, maize_prod_sum,
             soybean_prod_sum, soybean_prod_sum, soybean_prod_sum)
pot_prod = c(wheat_potprod_sum, wheat_potprod_sum, wheat_potprod_sum,
             maize_potprod_sum, maize_potprod_sum, maize_potprod_sum,
             soybean_potprod_sum, soybean_potprod_sum, soybean_potprod_sum)
comp_abs_loss = c(wheat_s_totloss, wheat_m_totloss, wheat_l_totloss,
                  maize_s_totloss, maize_m_totloss, maize_l_totloss,
                  soybean_s_totloss, soybean_m_totloss, soybean_l_totloss)
comp_perc_loss = c(wheat_s_percloss, wheat_m_percloss, wheat_l_percloss,
                   maize_s_percloss, maize_m_percloss, maize_l_percloss,
                   soybean_s_percloss, soybean_m_percloss, soybean_l_percloss)
comp_rt_abs_loss = c(wheat_rt_s_totloss, wheat_rt_m_totloss, wheat_rt_l_totloss,
                     maize_rt_s_totloss, maize_rt_m_totloss, maize_rt_l_totloss,
                     soybean_rt_s_totloss, soybean_rt_m_totloss, soybean_rt_l_totloss)
comp_rt_perc_loss = c(wheat_rt_s_percloss, wheat_rt_m_percloss, wheat_rt_l_percloss,
                      maize_rt_s_percloss, maize_rt_m_percloss, maize_rt_l_percloss,
                      soybean_rt_s_percloss, soybean_rt_m_percloss, soybean_rt_l_percloss)
comp_nt_abs_loss = c(wheat_nt_s_totloss, wheat_nt_m_totloss, wheat_nt_l_totloss,
                     maize_nt_s_totloss, maize_nt_m_totloss, maize_nt_l_totloss,
                     soybean_nt_s_totloss, soybean_nt_m_totloss, soybean_nt_l_totloss)
comp_nt_perc_loss = c(wheat_nt_s_percloss, wheat_nt_m_percloss, wheat_nt_l_percloss,
                      maize_nt_s_percloss, maize_nt_m_percloss, maize_nt_l_percloss,
                      soybean_nt_s_percloss, soybean_nt_m_percloss, soybean_nt_l_percloss)

comp_abs = c(comp_abs_loss, comp_rt_abs_loss, comp_nt_abs_loss)
comp_perc = c(comp_perc_loss, comp_rt_perc_loss, comp_nt_perc_loss)


################################

# Calculation of erosion impacts

################################

r_w = raster('./data/prepared/krls-factor_10km_weighted_median.tif')
r = raster('./data/prepared/krls-factor_10km_median.tif')
r_w[r_w == 0] = NA
krls = cover(r_w, r)

conversion = conversion_factor * time_horizon


# Erosion losses per ha-yr

# CP-factor [-] * KRLS-factor [t/ha-yr] * conversion factor [% yield loss/(t/ha-yr)]
#                                                     = % yield loss * ha-yr / ha-yr

# Conventional
yl_wheat_eros = df[['cp']][1] * krls * conversion
yl_wheat_eros[yl_wheat_eros > 100] = 100
yl_maize_eros = df[['cp']][4] * krls * conversion
yl_maize_eros[yl_maize_eros > 100] = 100
yl_soybean_eros = df[['cp']][7] * krls * conversion
yl_soybean_eros[yl_soybean_eros > 100] = 100

# Reduced tillage
yl_wheat_rt_eros = df[['cp']][10] * krls * conversion
yl_wheat_rt_eros[yl_wheat_rt_eros > 100] = 100
yl_maize_rt_eros = df[['cp']][13] * krls * conversion
yl_maize_rt_eros[yl_maize_rt_eros > 100] = 100
yl_soybean_rt_eros = df[['cp']][16] * krls * conversion
yl_soybean_rt_eros[yl_soybean_rt_eros > 100] = 100

# No tillage
yl_wheat_nt_eros = df[['cp']][19] * krls * conversion
yl_wheat_nt_eros[yl_wheat_nt_eros > 100] = 100
yl_maize_nt_eros = df[['cp']][22] * krls * conversion
yl_maize_nt_eros[yl_maize_nt_eros > 100] = 100
yl_soybean_nt_eros = df[['cp']][25] * krls * conversion
yl_soybean_nt_eros[yl_soybean_nt_eros > 100] = 100


#################

# Erosion losses

# Erosion losses per ha-yr * potential yield per crop cycle * area * cropy cycles per year
# = Compaction losses per ha-yr * potential production
# %_yield_loss*ha-yr/ha-yr * t/ha/cc * ha  * cc/yr = t / yr

# Conventional

# Wheat
wheat_eros_losses = yl_wheat_eros / 100 * wheat_potprod
wheat_eros_totloss = cellStats(wheat_eros_losses, sum)
wheat_eros_percloss = cellStats(wheat_eros_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_eros_losses = yl_maize_eros / 100 * maize_potprod
maize_eros_totloss = cellStats(maize_eros_losses, sum)
maize_eros_percloss = cellStats(maize_eros_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_eros_losses = yl_soybean_eros / 100 * soybean_potprod
soybean_eros_totloss = cellStats(soybean_eros_losses, sum)
soybean_eros_percloss = cellStats(soybean_eros_losses, sum) / soybean_potprod_sum * 100

# Reduced tillage

# Wheat
wheat_rt_eros_losses = yl_wheat_rt_eros / 100 * wheat_potprod
wheat_rt_eros_totloss = cellStats(wheat_rt_eros_losses, sum)
wheat_rt_eros_percloss = cellStats(wheat_rt_eros_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_rt_eros_losses = yl_maize_rt_eros / 100 * maize_potprod
maize_rt_eros_totloss = cellStats(maize_rt_eros_losses, sum)
maize_rt_eros_percloss = cellStats(maize_rt_eros_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_rt_eros_losses = yl_soybean_rt_eros / 100 * soybean_potprod
soybean_rt_eros_totloss = cellStats(soybean_rt_eros_losses, sum)
soybean_rt_eros_percloss = cellStats(soybean_rt_eros_losses, sum) / soybean_potprod_sum * 100

# No tillage

# Wheat
wheat_nt_eros_losses = yl_wheat_nt_eros / 100 * wheat_potprod
wheat_nt_eros_totloss = cellStats(wheat_nt_eros_losses, sum)
wheat_nt_eros_percloss = cellStats(wheat_nt_eros_losses, sum) / wheat_potprod_sum * 100

# Maize
maize_nt_eros_losses = yl_maize_nt_eros / 100 * maize_potprod
maize_nt_eros_totloss = cellStats(maize_nt_eros_losses, sum)
maize_nt_eros_percloss = cellStats(maize_nt_eros_losses, sum) / maize_potprod_sum * 100

# Soybean
soybean_nt_eros_losses = yl_soybean_nt_eros / 100 * soybean_potprod
soybean_nt_eros_totloss = cellStats(soybean_nt_eros_losses, sum)
soybean_nt_eros_percloss = cellStats(soybean_nt_eros_losses, sum) / soybean_potprod_sum * 100

# Collect erosion results
eros_abs_loss = c(wheat_eros_totloss, wheat_eros_totloss, wheat_eros_totloss,
                  maize_eros_totloss, maize_eros_totloss, maize_eros_totloss,
                  soybean_eros_totloss, soybean_eros_totloss, soybean_eros_totloss)
eros_perc_loss = c(wheat_eros_percloss, wheat_eros_percloss, wheat_eros_percloss,
                   maize_eros_percloss, maize_eros_percloss, maize_eros_percloss,
                   soybean_eros_percloss, soybean_eros_percloss, soybean_eros_percloss)
eros_rt_abs_loss = c(wheat_rt_eros_totloss, wheat_rt_eros_totloss, wheat_rt_eros_totloss,
                     maize_rt_eros_totloss, maize_rt_eros_totloss, maize_rt_eros_totloss,
                     soybean_rt_eros_totloss, soybean_rt_eros_totloss, soybean_rt_eros_totloss)
eros_rt_perc_loss = c(wheat_rt_eros_percloss, wheat_rt_eros_percloss, wheat_rt_eros_percloss,
                      maize_rt_eros_percloss, maize_rt_eros_percloss, maize_rt_eros_percloss,
                      soybean_rt_eros_percloss, soybean_rt_eros_percloss, soybean_rt_eros_percloss)
eros_nt_abs_loss = c(wheat_nt_eros_totloss, wheat_nt_eros_totloss, wheat_nt_eros_totloss,
                     maize_nt_eros_totloss, maize_nt_eros_totloss, maize_nt_eros_totloss,
                     soybean_nt_eros_totloss, soybean_nt_eros_totloss, soybean_nt_eros_totloss)
eros_nt_perc_loss = c(wheat_nt_eros_percloss, wheat_nt_eros_percloss, wheat_nt_eros_percloss,
                      maize_nt_eros_percloss, maize_nt_eros_percloss, maize_nt_eros_percloss,
                      soybean_nt_eros_percloss, soybean_nt_eros_percloss, soybean_nt_eros_percloss)

eros_abs = c(eros_abs_loss, eros_rt_abs_loss, eros_nt_abs_loss)
eros_perc = c(eros_perc_loss, eros_rt_perc_loss, eros_nt_perc_loss)


##############################

# Collect results in dataframe

##############################

activity = c('wheat production, global, small',
             'wheat production, global, medium',
             'wheat production, global, large',
             'maize grain production, global, small',
             'maize grain production, global, medium',
             'maize grain production, global, large',
             'soybean production, global, small',
             'soybean production, global, medium',
             'soybean production, global, large',
             'wheat production, reduced tillage, global, small',
             'wheat production, reduced tillage, global, medium',
             'wheat production, reduced tillage, global, large',
             'maize grain production, reduced tillage, global, small',
             'maize grain production, reduced tillage, global, medium',
             'maize grain production, reduced tillage, global, large',
             'soybean production, reduced tillage, global, small',
             'soybean production, reduced tillage, global, medium',
             'soybean production, reduced tillage, global, large',
             'wheat production, no tillage, global, small',
             'wheat production, no tillage, global, medium',
             'wheat production, no tillage, global, large',
             'maize grain production, no tillage, global, small',
             'maize grain production, no tillage, global, medium',
             'maize grain production, no tillage, global, large',
             'soybean production, no tillage, global, small',
             'soybean production, no tillage, global, medium',
             'soybean production, no tillage, global, large')



results = data.frame(row.names=1, activity, act_prod, pot_prod,
                     comp_abs, comp_perc, eros_abs, eros_perc)

results

write.table(results, 'impacts.csv', sep=',')


"""
###############################

# Original actual production in one year
# actual yield [t/ha] * area harvested [ha] * 1 year [yr] = t (per cell)

# Data vs. area*yield vs. actual area*yield

wheat_prod_data = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/wheat/wheat_Production.tif')
wheat_yield = func_cleanup_raster(wheat_yield, mx_ts)
cellStats(wheat_prod_data, sum)

wheat_prod_calc = wheat_area * wheat_yield 
cellStats(wheat_prod_calc, sum)

wheat_prod_calc2 = wheat_actarea * wheat_yield 
cellStats(wheat_prod_calc2, sum)

maize_prod_data = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/maize/maize_Production.tif')
maize_yield = func_cleanup_raster(maize_yield, mx_ts)
cellStats(maize_prod_data, sum)

maize_prod_calc = maize_area * maize_yield 
cellStats(maize_prod_calc, sum)

maize_prod_calc2 = maize_actarea * maize_yield 
cellStats(maize_prod_calc2, sum)

soybean_prod_data = raster('./data/EarthStat/HarvestedAreaYield175Crops_Geotiff/soybean/soybean_Production.tif')
soybean_yield = func_cleanup_raster(soybean_yield, mx_ts)
cellStats(soybean_prod_data, sum)

soybean_prod_calc = soybean_area * soybean_yield 
cellStats(soybean_prod_calc, sum)

soybean_prod_calc2 = soybean_actarea * soybean_yield 
cellStats(soybean_prod_calc2, sum)
"""
