export interface ChartData {
  labels: string[];
  datasets: Dataset[];
}

export interface Dataset {
  label: string;
  data: number[];
  backgroundColor?: string | string[];
  borderColor?: string;
  borderWidth?: number;
}

export class DataVisualizer {
  static createLineChartData(
    labels: string[],
    dataPoints: number[],
    label: string = 'Data'
  ): ChartData {
    return {
      labels,
      datasets: [
        {
          label,
          data: dataPoints,
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          borderWidth: 2,
        },
      ],
    };
  }

  static createBarChartData(
    labels: string[],
    dataPoints: number[],
    label: string = 'Data'
  ): ChartData {
    return {
      labels,
      datasets: [
        {
          label,
          data: dataPoints,
          backgroundColor: [
            'rgba(255, 99, 132, 0.6)',
            'rgba(54, 162, 235, 0.6)',
            'rgba(255, 206, 86, 0.6)',
            'rgba(75, 192, 192, 0.6)',
            'rgba(153, 102, 255, 0.6)',
          ],
        },
      ],
    };
  }

  static createPieChartData(labels: string[], dataPoints: number[]): ChartData {
    return {
      labels,
      datasets: [
        {
          label: 'Distribution',
          data: dataPoints,
          backgroundColor: [
            'rgba(255, 99, 132, 0.6)',
            'rgba(54, 162, 235, 0.6)',
            'rgba(255, 206, 86, 0.6)',
            'rgba(75, 192, 192, 0.6)',
            'rgba(153, 102, 255, 0.6)',
            'rgba(255, 159, 64, 0.6)',
          ],
        },
      ],
    };
  }

  static aggregateByDay(data: Array<{ date: Date; value: number }>): ChartData {
    const grouped = new Map<string, number>();

    for (const item of data) {
      const dateKey = item.date.toISOString().split('T')[0];
      grouped.set(dateKey, (grouped.get(dateKey) || 0) + item.value);
    }

    const labels = Array.from(grouped.keys()).sort();
    const values = labels.map((label) => grouped.get(label) || 0);

    return this.createLineChartData(labels, values, 'Daily Values');
  }

  static calculateMovingAverage(data: number[], window: number): number[] {
    const result: number[] = [];

    for (let i = 0; i < data.length; i++) {
      const start = Math.max(0, i - window + 1);
      const slice = data.slice(start, i + 1);
      const avg = slice.reduce((a, b) => a + b, 0) / slice.length;
      result.push(avg);
    }

    return result;
  }

  static normalizeData(data: number[]): number[] {
    const max = Math.max(...data);
    const min = Math.min(...data);
    const range = max - min;

    return data.map((val) => (val - min) / range);
  }
}
