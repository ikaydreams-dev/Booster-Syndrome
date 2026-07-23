import pandas as pd
import numpy as np
from datetime import datetime, timedelta

class DataProcessor:
    @staticmethod
    def aggregate_events_by_hour(events):
        if not events:
            return []

        df = pd.DataFrame(events)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df.set_index('timestamp', inplace=True)

        hourly = df.resample('H').size().to_dict()
        return [{"hour": str(k), "count": int(v)} for k, v in hourly.items()]

    @staticmethod
    def calculate_percentiles(values):
        if not values:
            return {}

        return {
            "p50": float(np.percentile(values, 50)),
            "p75": float(np.percentile(values, 75)),
            "p90": float(np.percentile(values, 90)),
            "p95": float(np.percentile(values, 95)),
            "p99": float(np.percentile(values, 99)),
        }

    @staticmethod
    def detect_anomalies(data, threshold=2):
        if len(data) < 3:
            return []

        arr = np.array(data)
        mean = np.mean(arr)
        std = np.std(arr)

        anomalies = []
        for i, value in enumerate(arr):
            z_score = (value - mean) / std if std > 0 else 0
            if abs(z_score) > threshold:
                anomalies.append({"index": i, "value": float(value), "z_score": float(z_score)})

        return anomalies

    @staticmethod
    def calculate_growth_rate(current, previous):
        if previous == 0:
            return 0

        return ((current - previous) / previous) * 100
