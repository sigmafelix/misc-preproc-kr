# data source: data.go.kr and SSiS

import pandas as pd
import re
import glob
import os

basedir = "/mnt/s/Korea/welfare/cleaned"
parquets = glob.glob(os.path.join(basedir, "*.parquet"))

basic_living_sec = parquets[0]
basic_living_sec_df = pd.read_parquet(basic_living_sec)
# ['통계연월', '통계시도명', '통계시군구명', '수급자구분', '수급자수', '수급가구수', 'data_description',
      #  'source_file']
basic_living_sec_df = basic_living_sec_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '수급자구분': 'benefit_recipient_type',
    '수급자수': 'num_beneficiaries',
    '수급가구수': 'num_beneficiary_households'
})


# basic living security income age_sex
basic_living_sec_as = parquets[1]
basic_living_sec_as_df = pd.read_parquet(basic_living_sec_as)
# ['통계연월', '통계시도명', '통계시군구명', '수급자구분', '연령구간', '성별', '수급자수',
#        'data_description', 'source_file']
basic_living_sec_as_df = basic_living_sec_as_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '수급자구분': 'benefit_recipient_type',
    '연령구간': 'age_group',
    '성별': 'sex',
    '수급자수': 'num_beneficiaries'
})


# basic living security income by households with physically or mentally challenged
basic_living_sec_physical_mental = parquets[2]
basic_living_sec_physical_mental_df = pd.read_parquet(basic_living_sec_physical_mental)
# ['통계연월', '통계시도명', '통계시군구명', '수급자구분', '연령대',
#  '장애인포함수급가구수', '장애인수급자수',
#        'data_description', 'source_file']
basic_living_sec_physical_mental_df = \
    basic_living_sec_physical_mental_df.rename(columns={
      '통계연월': 'year_month',
      '통계시도명': 'adm1kr',
      '통계시군구명': 'adm2kr',
      '수급자구분': 'benefit_recipient_type',
      '연령대': 'age_group',
      '장애인포함수급가구수': 'num_beneficiary_households_pc',
      '장애인수급자수': 'num_beneficiaries_pc'
    })


# basic pension
basic_pension = parquets[3]
basic_pension_df = pd.read_parquet(basic_pension)
# ['통계연월', '통계시도명', '통계시군구명', '성별구분', '수급자수', 'data_description',
#        'source_file']
basic_pension_df = basic_pension_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '성별구분': 'sex_type',
    '수급자수': 'num_beneficiaries'
})


# facilities
facilities = parquets[4]
facilities_df = pd.read_parquet(facilities)
# ['통계연월', '통계시도명', '통계시군구명', '시설구분', '복지시설수', 'data_description', 'source_file']
facilities_df = facilities_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '시설구분': 'facility_type',
    '복지시설수': 'num_welfare_facilities'
})


# child-headed families
child_headed_families = parquets[5]
child_headed_families_df = pd.read_parquet(child_headed_families)
# ['통계연월', '통계시도명', '통계시군구명', '연령구간', '성별', '수급자수', 'data_description', 'source_file']
child_headed_families_df = child_headed_families_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '연령구간': 'age_group',
    '성별': 'sex',
    '수급자수': 'num_beneficiaries'
})


# registered physically/mentally challenged persons
registered_pc = parquets[6]
registered_pc_df = pd.read_parquet(registered_pc)
# ['통계연월', '통계시도명', '통계시군구명', '연령구간', '성별', '등록장애인수', 'data_description', 'source_file']
registered_pc_df = registered_pc_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '연령': 'age_group',
    '성별': 'sex',
    '등록장애인수': 'num_registered_pc'
})

# registered physically/mentally challenged persons by severity
registered_pc_severity = parquets[7]
registered_pc_severity_df = pd.read_parquet(registered_pc_severity)
# ['통계연월', '통계시도명', '통계시군구명', '연령', '성별', '장애정도', '등록장애인수', 'data_description',
#        'source_file', '장애등급']
# remove 장애등급
registered_pc_severity_df = registered_pc_severity_df.drop(columns=['장애등급'])
registered_pc_severity_df = registered_pc_severity_df.rename(columns={
     '통계연월': 'year_month',
     '통계시도명': 'adm1kr',
     '통계시군구명': 'adm2kr',
     '연령': 'age_group',
     '성별': 'sex',
     '장애정도': 'severity_level',
     '등록장애인수': 'num_registered_pc'
})


# single-parent households
single_parent_households = parquets[8]
single_parent_households_df = pd.read_parquet(single_parent_households)
# ['통계연월', '통계시도명', '통계시군구명', '중위소득비율구분', '가족유형', '수급자수', '수급가구수']
single_parent_households_df = single_parent_households_df.rename(columns={
    '통계연월': 'year_month',
    '통계시도명': 'adm1kr',
    '통계시군구명': 'adm2kr',
    '중위소득비율구분': 'median_income_ratio_type',
    '가족유형': 'family_type',
    '수급자수': 'num_beneficiaries',
    '수급가구수': 'num_beneficiary_households'
})

# list of dataframes without unnecessary fields
welfare_dfs = [
    basic_living_sec_df,
    basic_living_sec_as_df,
    basic_living_sec_physical_mental_df,
    basic_pension_df,
    facilities_df,
    child_headed_families_df,
    registered_pc_df,
    registered_pc_severity_df,
    single_parent_households_df
]
welfare_df_labels = [
    "basic_living_security",
    "basic_living_security_age_sex",
    "basic_living_security_physical_mental",
    "basic_pension",
    "facilities",
    "child_headed_families",
    "registered_physically_mentally_challenged",
    "registered_physically_mentally_challenged_severity",
    "single_parent_households"
]

# unnecessary fields to drop
unnecessary_fields = [
    'data_description',
    'source_file'
]
for df in welfare_dfs:
    for field in unnecessary_fields:
        if field in df.columns:
            df.drop(columns=[field], inplace=True)

# # Save cleaned dataframes back to parquet
# output_dir = "/mnt/s/Korea/welfare/standardized"
# os.makedirs(output_dir, exist_ok=True)

# for i, df in enumerate(welfare_dfs):
#     output_path = os.path.join(output_dir, f"welfare_data_{i+1}.parquet")
#     df.to_parquet(output_path, index=False, engine='pyarrow')
#     print(f"Saved cleaned dataframe {i+1} to {output_path}")


