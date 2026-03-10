
import os, sys
import pandas as pd
import geopandas as gpd
import glob

# use directory
data_dir = "/media/isong/sds/Korea/energy/pv"

# read the csv
csv = glob.glob(os.path.join(data_dir, "*.csv"))

pv = pd.read_csv(csv[0])

pv_gdf = gpd.GeoDataFrame(pv, geometry=gpd.points_from_xy(pv.wgs84_lltd_xcrd, pv.wgs84_lltd_ycrd), crs = "EPSG:4326")
pv_gdf.to_parquet(os.path.join(data_dir, "pv.parquet"))
pv_gdf.to_file(os.path.join(data_dir, "pv.gpkg"))

