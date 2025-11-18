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

