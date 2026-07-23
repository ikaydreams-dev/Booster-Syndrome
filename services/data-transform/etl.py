import pandas as pd
from typing import Callable, List, Dict, Any

class ETLPipeline:
    def __init__(self):
        self.transformations = []

    def add_transformation(self, func: Callable):
        """Add transformation function to pipeline"""
        self.transformations.append(func)
        return self

    def execute(self, data: pd.DataFrame) -> pd.DataFrame:
        """Execute all transformations"""
        result = data.copy()
        for transform in self.transformations:
            result = transform(result)
        return result

    def extract_csv(self, filepath: str) -> pd.DataFrame:
        """Extract data from CSV"""
        return pd.read_csv(filepath)

    def extract_json(self, filepath: str) -> pd.DataFrame:
        """Extract data from JSON"""
        return pd.read_json(filepath)

    def load_csv(self, data: pd.DataFrame, filepath: str):
        """Load data to CSV"""
        data.to_csv(filepath, index=False)

    def load_json(self, data: pd.DataFrame, filepath: str):
        """Load data to JSON"""
        data.to_json(filepath, orient='records')

class DataTransformer:
    @staticmethod
    def filter_rows(condition: Callable) -> Callable:
        """Filter rows based on condition"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df[df.apply(condition, axis=1)]
        return transform

    @staticmethod
    def select_columns(columns: List[str]) -> Callable:
        """Select specific columns"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df[columns]
        return transform

    @staticmethod
    def rename_columns(mapping: Dict[str, str]) -> Callable:
        """Rename columns"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df.rename(columns=mapping)
        return transform

    @staticmethod
    def add_column(name: str, func: Callable) -> Callable:
        """Add new column"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            df[name] = df.apply(func, axis=1)
            return df
        return transform

    @staticmethod
    def remove_duplicates() -> Callable:
        """Remove duplicate rows"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df.drop_duplicates()
        return transform

    @staticmethod
    def fill_missing(strategy: str = 'mean') -> Callable:
        """Fill missing values"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            if strategy == 'mean':
                return df.fillna(df.mean())
            elif strategy == 'median':
                return df.fillna(df.median())
            elif strategy == 'zero':
                return df.fillna(0)
            return df
        return transform

    @staticmethod
    def group_by(columns: List[str], agg: Dict[str, str]) -> Callable:
        """Group by columns and aggregate"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df.groupby(columns).agg(agg).reset_index()
        return transform

    @staticmethod
    def sort_by(columns: List[str], ascending: bool = True) -> Callable:
        """Sort by columns"""
        def transform(df: pd.DataFrame) -> pd.DataFrame:
            return df.sort_values(by=columns, ascending=ascending)
        return transform

etl_pipeline = ETLPipeline()
