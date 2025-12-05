## Date: 2025-12-05
## Title: Ingest Economic Population Data
## Description: This script ingests economic population data from a CSV file

import pandas as pd
import os
import glob
import re

# detect all csv file paths
basepath = "~/Downloads/employees/data"
filepaths = glob.glob(os.path.join(os.path.expanduser(basepath), "*.csv"))

# explore the file structure
idx = [2, 30]
df = pd.read_csv(filepaths[idx[2]], encoding = "euc-kr", skiprows = 1)
print(df.head())
print(df.info())
df = pd.read_csv(filepaths[idx[30]], encoding = "euc-kr", skiprows = 1)
print(df.head())
print(df.info())


# read all files in a list
# names of columns
column_names = [
    'sggcd', 'sggnm', 'industry_cd', 'industry_nm', 'scale_cd', 'scale_nm',
    'year', 'n_self_emp', 'n_nonpaid_family', 'n_employees', 'n_temp']
# data types



def detect_trial(path):
    dtypes_dict1 = {
        "sggcd": "str",
        "sggnm": "str",
        "industry_cd": "str",
        "industry_nm": "str",
        "scale_cd": "str",
        "scale_nm": "str",
        "year": "str",
        "n_self_emp_m": "int64",
        "n_self_emp_f": "int64",
        "n_nonpaid_family_m": "int64",
        "n_nonpaid_family_f": "int64",
        "n_employees_m": "int64",
        "n_employees_f": "int64",
        "n_temp_m": "int64",
        "n_temp_f": "int64"
    }
    dtypes_dict2 = {
        "sggcd": "str",
        "sggnm": "str",
        "industry_cd": "str",
        "industry_nm": "str",
        "scale_cd": "str",
        "scale_nm": "str",
        "year": "str",
        "n_self_emp": "int64",
        "n_nonpaid_family": "int64",
        "n_employees": "int64",
        "n_temp": "int64",
    }
    # dtypes_dict
    df_trial = pd.read_csv(
        path,
        encoding = "euc-kr",
        skiprows = 2,
        nrows = 5
    )
    df_flag = pd.read_csv(
        path,
        encoding = "euc-kr",
        nrows = 1
    )
    # detect gender from the first row
    if re.search('남자', str(df_flag.iloc[0,0])) is not None:
        suffix = '_m'
    else:
        suffix = '_f'
    
    ncol = df_trial.shape[1]
    
    if ncol == 15:
        dtyper = dtypes_dict1.copy()
    else:
        dtyper = dtypes_dict2.copy()
        # paste suffix at 7-11th elements
        for key in ['n_self_emp', 'n_nonpaid_family', 'n_employees', 'n_temp']:
            new_key = key + suffix
            dtyper[new_key] = dtyper.pop(key)
    print(dtyper)
    df_real = pd.read_csv(
        path,
        encoding = "euc-kr",
        skiprows = 3,
        na_values = ["*", "-"],
        names = dtyper.keys(),
        dtype = dtyper
    )
    return df_real


data_list = [detect_trial(fp) for fp in filepaths]
for df in data_list:
    print(df.columns)

# bind rows
econpop_df = pd.concat(data_list, axis = 0, ignore_index = True)

