from celery import Celery
import pandas as pd
import numpy as np

app = Celery('data_tasks', broker='redis://localhost:6379/0')

@app.task
def process_csv_task(file_path):
    """Process CSV file"""
    try:
        df = pd.read_csv(file_path)

        result = {
            'rows': len(df),
            'columns': len(df.columns),
            'memory_usage': df.memory_usage(deep=True).sum(),
            'summary': df.describe().to_dict()
        }

        return result
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}

@app.task
def aggregate_data_task(data, aggregation_type='sum'):
    """Aggregate data"""
    try:
        arr = np.array(data)

        if aggregation_type == 'sum':
            result = np.sum(arr)
        elif aggregation_type == 'mean':
            result = np.mean(arr)
        elif aggregation_type == 'median':
            result = np.median(arr)
        else:
            result = np.sum(arr)

        return {'result': float(result), 'type': aggregation_type}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}
