# Assumed to have run standardize_welfare_data.py before this script

import pandas as pd
import re
import os

welfare_dfs
welfare_df_labels = [
    "basic living security",
    "basic living security age sex",
    "basic living security for the physically or mentally challenged people",
    "basic pension",
    "welfare facilities",
    "child headed families",
    "registered physically or mentally challenged people",
    "registered physically or mentally challenged people by severity",
    "single-parent households"
]
welfare_df_type_labels = [
    "social security",
    "social security",
    "social security",
    "social security",
    "welfare",
    "welfare",
    "welfare",
    "welfare",
    "welfare"
]

welfare_df_class1_labels = [
    "basic living security",
    "basic living security",
    "basic living security",
    "basic pension",
    "facilities",
    "child headed households",
    "registered physically mentally challenged",
    "registered physically mentally challenged severity",
    "single parent households"
]


# filter each dataframe by year_month is any of 201012, 201512, 202012
filtered_welfare_dfs = []
target_year_months = ['201012', '201512', '202012']
for df in welfare_dfs:
    filtered_df = df[df['year_month'].astype(str).isin(target_year_months)].reset_index(drop=True)
    filtered_welfare_dfs.append(filtered_df)

for df in filtered_welfare_dfs:
    print(df.columns.tolist())

# assign labels and extract year from year_month
for i, df in enumerate(filtered_welfare_dfs):
    df['year'] = df['year_month'].astype(str).str.slice(0, 4).astype(int)
    df['type'] = welfare_df_type_labels[i]
    df['class1'] = welfare_df_class1_labels[i]

# pivot dataframes if necessary
# key fields to keep
key_fields = ['adm1kr', 'adm2kr', 'year', 'type', 'class1', 'age_group']
# value columns starting with "num_"
value_column_pattern = re.compile(r'^num_')

pivoted_welfare_dfs = []
for df in filtered_welfare_dfs:
    df = df.drop(columns=['year_month'])
    value_columns = [col for col in df.columns if value_column_pattern.match(col)]
    key_columns = [col for col in df.columns if col in key_fields]
    if len(value_columns) > 1:
        # pivot the dataframe
        pivot_df = df.melt(id_vars=key_columns, value_vars=value_columns,
                           var_name='measure', value_name='value')
        pivoted_welfare_dfs.append(pivot_df)
    else:
        pivoted_welfare_dfs.append(df)


# drop the first
pivoted_welfare_dfs_r = pivoted_welfare_dfs[1:]



# column cleaning
pivoted_welfare_dfs_r[0] = pivoted_welfare_dfs_r[0].rename(columns={
    'num_beneficiaries': 'value'
})
pivoted_welfare_dfs_r['unit'] = 'persons'
pivoted_welfare_dfs_r[1] = pivoted_welfare_dfs_r[1].rename(columns={
    'num_beneficiaries': 'value'
})
# unit: "households" if measure is "num_beneficiary_households", else "persons"
def assign_unit(row):
    if row['measure'] == 'num_beneficiary_households':
        return 'households'
    else:
        return 'persons'

pivoted_welfare_dfs_r[1]['unit'] = pivoted_welfare_dfs_r[1].apply(assign_unit, axis=1)
pivoted_welfare_dfs_r[2] = pivoted_welfare_dfs_r[2].rename(columns={
    'num_beneficiaries': 'value'
})
pivoted_welfare_dfs_r[2]['unit'] = 'persons'
pivoted_welfare_dfs_r[3] = pivoted_welfare_dfs_r[3].rename(columns={
    'num_welfare_facilities': 'value'
})
pivoted_welfare_dfs_r[3]['unit'] = 'count'

# 4: needs aggregation
pivoted_welfare_dfs_r[4] = pivoted_welfare_dfs_r[4].rename(columns={
    'num_beneficiaries': 'value'
})
pivoted_welfare_dfs_r[4]['unit'] = 'households'

# 5: needs aggregation
pivoted_welfare_dfs_r[5] = pivoted_welfare_dfs_r[5].drop(
    ['data_description', 'source_file'], axis=1, errors='ignore')
pivoted_welfare_dfs_r[5] = pivoted_welfare_dfs_r[5].rename(columns={
    'num_registered_pc': 'value'
})
pivoted_welfare_dfs_r[5]['unit'] = 'persons'

# 6
pivoted_welfare_dfs_r[6] = pivoted_welfare_dfs_r[6].rename(columns={
    'num_registered_pc': 'value'
})
pivoted_welfare_dfs_r[6]['unit'] = 'persons'

# 7
pivoted_welfare_dfs_r[7]['unit'] = pivoted_welfare_dfs_r[7].apply(assign_unit, axis=1)


# save list to pickle
import pickle
pickle.dump(pivoted_welfare_dfs_r, open(
    os.path.join(basedir, "standardized_filtered_welfare_dfs.pkl"), "wb")
)


# rowbind all dataframes into a single dataframe
concat_welfare_df = pd.concat(pivoted_welfare_dfs_r, ignore_index=False)
concat_welfare_df = concat_welfare_df.reset_index(drop=True)
concat_welfare_df.to_parquet(
    os.path.join(basedir, "standardized_filtered_welfare_data.parquet"),
    index=False, engine='pyarrow'
)