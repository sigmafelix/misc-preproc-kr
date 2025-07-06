Miscellaneous codes to ingest regional covariates in Korea for spatial analysis

------

## Description
This repository contains miscellaneous codes to ingest regional covariates in Korea for spatial analysis. The codes may be based on R or Python, depending on the author's need and analysis workflow.

## List

- Directory structure follows Group-Title hierarchy. The title may be abbreviated for convenience.


| Group | Title | Scale | Temporal | Data source | Remarks |
| ------- | ------- | ------- | ------------- |--------- | --------- |
| Energy | Electricity usage | District | 2004-Current (monthly) | [KEPCO](https://home.kepco.co.kr/kepco/KO/ntcob/list.do?boardCd=BRD_000283&menuCd=FN05030105) | Manual download |
| Emission | Air pollutant emission | District | 2004-Current (annual) | [Opendata Korea](https://www.data.go.kr/data/15068820/fileData.do) | Manual download |
| Emission | Air pollutant emission locations | Location | Rolling | [Opendata Korea](https://www.data.go.kr/data/15044957/fileData.do) | Manual download |


## TODO
- Add more data sources
- Consider `renv` or `conda` for reproducibility