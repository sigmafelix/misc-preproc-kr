#--- coding: utf-8 -*-
# Note: Gemini-powered script. Take your own risks when running it. Always review the code before executing.
# Input: HWPX file path
# Output: Excel file with all tables concatenated into a single sheet

import zipfile
import xml.etree.ElementTree as ET
import pandas as pd

# HWPX OWPML 네임스페이스
HWPX_NS = {'hp': 'http://www.hancom.co.kr/hwpml/2011/paragraph'}

def extract_tables_from_hwpx(hwpx_path):
    """HWPX 파일에서 표 데이터를 추출합니다. (줄바꿈은 콜론으로 대체)"""
    tables_data = []
    
    with zipfile.ZipFile(hwpx_path, 'r') as hwpx:
        # 본문 XML 파일 찾기 및 정렬
        section_files = [f for f in hwpx.namelist() if f.startswith('Contents/section') and f.endswith('.xml')]
        section_files.sort()
        
        for sec_file in section_files:
            xml_content = hwpx.read(sec_file)
            root = ET.fromstring(xml_content)
            
            for tbl in root.findall('.//hp:tbl', HWPX_NS):
                table_data = []
                for tr in tbl.findall('.//hp:tr', HWPX_NS):
                    row_data = []
                    for tc in tr.findall('.//hp:tc', HWPX_NS):
                        cell_texts = []
                        # 문단(<hp:p>) 단위로 텍스트 모으기
                        for p in tc.findall('.//hp:p', HWPX_NS):
                            p_texts = [t.text for t in p.findall('.//hp:t', HWPX_NS) if t.text]
                            if p_texts:
                                cell_texts.append(''.join(p_texts))
                        
                        # 1. 문단과 문단 사이를 개행 대신 ':'로 연결
                        cell_string = ':'.join(cell_texts).strip()
                        
                        # 2. 텍스트 자체에 포함된 \n, \r 등의 이스케이프 문자도 확실하게 콜론으로 치환
                        cell_string = cell_string.replace('\r\n', ':').replace('\n', ':').replace('\r', '')
                        
                        row_data.append(cell_string)
                        
                    table_data.append(row_data)
                
                if table_data:
                    tables_data.append(table_data)
                    
    return tables_data

def save_tables_to_excel_concat(tables_data, output_excel_path):
    """추출된 표 데이터들을 pd.concat으로 병합하여 하나의 엑셀 시트에 저장합니다."""
    if not tables_data:
        print("추출할 표가 없습니다.")
        return
    
    df_list = []
    
    for i, table in enumerate(tables_data):
        df = pd.DataFrame(table)
        df_list.append(df)
        
        # 표 사이에 빈 행 삽입
        if i < len(tables_data) - 1:
            empty_row = pd.DataFrame([[None] * df.shape[1]])
            df_list.append(empty_row)
    
    # 병합
    combined_df = pd.concat(df_list, ignore_index=True)
    
    # 저장
    combined_df.to_excel(output_excel_path, index=False, header=False, engine='openpyxl')
    print(f"HWPX 파일의 표들이 하나의 시트로 병합되어 {output_excel_path}에 저장되었습니다.")

# ==========================================
# 실행 예시
# ==========================================
# hwpx_file = "2025+노인복지시설+현황.hwpx"
# excel_file = "extracted_tables_concat.xlsx"

# 추출 및 병합 실행
# extracted_tables = extract_tables_from_hwpx(hwpx_file)
# save_tables_to_excel_concat(extracted_tables, excel_file)