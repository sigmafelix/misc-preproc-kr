#!/usr/bin/env python3
"""
Clean welfare-related data from zip files.

This script:
1. Identifies all zip files in /mnt/s/Korea/welfare
2. For each zip file, unzips to temp directory, reads CSVs, combines by rows
3. Adds English description column by translating Korean file name
4. Saves each as a parquet file in /mnt/s/Korea/welfare/cleaned
"""

import os
import zipfile
import tempfile
import shutil
from pathlib import Path
import pandas as pd
from typing import List, Dict
import re


def translate_korean_filename(filename: str) -> str:
    """
    Translate Korean filename to English description.
    
    Args:
        filename: Korean filename (without extension)
    
    Returns:
        English description
    """
    # Common Korean welfare terms translation dictionary
    translations = {
        '복지': 'welfare',
        '수급': 'benefit recipient',
        '수급자': 'beneficiary',
        '기초': 'basic',
        '생활': 'living',
        '보장': 'security',
        '노인': 'elderly',
        '장애인': 'disabled',
        '아동': 'child',
        '청소년': 'youth',
        '여성': 'women',
        '한부모': 'single parent',
        '가족': 'family',
        '지원': 'support',
        '급여': 'benefit',
        '현황': 'status',
        '통계': 'statistics',
        '연도별': 'by year',
        '월별': 'by month',
        '시도별': 'by province',
        '시군구별': 'by district',
        '유형별': 'by type',
        '자활': 'self-sufficiency',
        '의료': 'medical',
        '주거': 'housing',
        '교육': 'education',
        '긴급': 'emergency',
        '재난': 'disaster',
        '돌봄': 'care',
        '서비스': 'service',
        '시설': 'facility',
        '센터': 'center',
        '프로그램': 'program',
        '예산': 'budget',
        '지출': 'expenditure',
        '인원': 'number of people',
        '가구': 'household',
        '세대': 'household',
    }
    
    # Replace Korean terms with English
    english_desc = filename
    for korean, english in translations.items():
        english_desc = english_desc.replace(korean, english)
    
    # Clean up the description
    english_desc = re.sub(r'[_\-]+', ' ', english_desc)
    english_desc = re.sub(r'\s+', ' ', english_desc).strip()
    
    return english_desc if english_desc != filename else filename


def find_zip_files(source_dir: str) -> List[Path]:
    """
    Find all zip files in the source directory.
    
    Args:
        source_dir: Source directory path
    
    Returns:
        List of Path objects for zip files
    """
    source_path = Path(source_dir)
    if not source_path.exists():
        raise ValueError(f"Source directory does not exist: {source_dir}")
    
    zip_files = list(source_path.glob("*.zip"))
    print(f"Found {len(zip_files)} zip files in {source_dir}")
    return zip_files


def process_zip_file(zip_path: Path, output_dir: Path) -> None:
    """
    Process a single zip file: extract, read CSVs, combine, and save as parquet.
    
    Args:
        zip_path: Path to the zip file
        output_dir: Output directory for parquet files
    """
    print(f"\nProcessing: {zip_path.name}")
    
    # Create temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # Extract zip file
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(temp_path)
            print(f"  Extracted to temporary directory")
        except Exception as e:
            print(f"  Error extracting {zip_path.name}: {e}")
            return
        
        # Find all CSV files in extracted directory
        csv_files = list(temp_path.rglob("*.csv"))
        if not csv_files:
            print(f"  No CSV files found in {zip_path.name}")
            return
        
        print(f"  Found {len(csv_files)} CSV files")
        
        # Read and combine all CSV files
        dataframes = []
        for csv_file in csv_files:
            try:
                # Try different encodings
                for encoding in ['utf-8', 'cp949', 'euc-kr', 'utf-8-sig']:
                    try:
                        df = pd.read_csv(csv_file, encoding=encoding)
                        print(f"    Read {csv_file.name} ({len(df)} rows, encoding: {encoding})")
                        
                        # Add description column based on CSV filename
                        csv_name = csv_file.stem  # filename without extension
                        english_desc = translate_korean_filename(csv_name)
                        df['data_description'] = english_desc
                        df['source_file'] = csv_file.name
                        
                        dataframes.append(df)
                        break
                    except UnicodeDecodeError:
                        continue
                else:
                    print(f"    Failed to read {csv_file.name} with any encoding")
            except Exception as e:
                print(f"    Error reading {csv_file.name}: {e}")
        
        if not dataframes:
            print(f"  No dataframes to combine for {zip_path.name}")
            return
        
        # Combine all dataframes by rows
        try:
            combined_df = pd.concat(dataframes, ignore_index=True)
            print(f"  Combined into single dataframe: {len(combined_df)} rows, {len(combined_df.columns)} columns")
        except Exception as e:
            print(f"  Error combining dataframes: {e}")
            return
        
        # Generate output filename (based on zip file name)
        output_filename = zip_path.stem + ".parquet"
        output_path = output_dir / output_filename
        
        # Save as parquet
        try:
            combined_df.to_parquet(output_path, index=False, engine='pyarrow')
            print(f"  Saved to: {output_path}")
            print(f"  ✓ Successfully processed {zip_path.name}")
        except Exception as e:
            print(f"  Error saving parquet file: {e}")


def main():
    """Main function to process all welfare zip files."""
    # Configuration
    source_dir = "/mnt/s/Korea/welfare"
    output_dir = Path("/mnt/s/Korea/welfare/cleaned")
    
    print("=" * 70)
    print("Welfare Data Cleaning Script")
    print("=" * 70)
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {output_dir}")
    
    # Find all zip files
    try:
        zip_files = find_zip_files(source_dir)
    except Exception as e:
        print(f"Error finding zip files: {e}")
        return
    
    if not zip_files:
        print("No zip files found to process.")
        return
    
    # Process each zip file
    for i, zip_path in enumerate(zip_files, 1):
        print(f"\n[{i}/{len(zip_files)}]", end=" ")
        process_zip_file(zip_path, output_dir)
    
    print("\n" + "=" * 70)
    print("Processing complete!")
    print(f"Output files saved to: {output_dir}")
    print("=" * 70)


if __name__ == "__main__":
    main()
