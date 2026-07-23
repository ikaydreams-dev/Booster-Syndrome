import React, { useEffect, useState } from 'react';
import { Line, Bar, Pie } from 'react-chartjs-2';

interface MetricData {
  timestamp: number;
  value: number;
}

interface DashboardData {
  activeUsers: number;
  requestsPerSecond: number;
  errorRate: number;
  responseTime: MetricData[];
  requestsByEndpoint: Record<string, number>;
  statusCodeDistribution: Record<string, number>;
}

export const RealtimeDashboard: React.FC = () => {
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [data, setData] = useState<DashboardData>({
    activeUsers: 0,
    requestsPerSecond: 0,
    errorRate: 0,
    responseTime: [],
    requestsByEndpoint: {},
    statusCodeDistribution: {},
  });

  useEffect(() => {
    const websocket = new WebSocket('ws://localhost:8080/ws/dashboard');

    websocket.onopen = () => {
      console.log('Dashboard WebSocket connected');
    };

    websocket.onmessage = (event) => {
      const newData = JSON.parse(event.data);
      setData((prev) => ({
        ...prev,
        ...newData,
        responseTime: [...prev.responseTime.slice(-50), newData.responseTime].filter(Boolean),
      }));
    };

    websocket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    websocket.onclose = () => {
      console.log('Dashboard WebSocket disconnected');
    };

    setWs(websocket);

    return () => {
      websocket.close();
    };
  }, []);

  const responseTimeData = {
    labels: data.responseTime.map((d) => new Date(d.timestamp).toLocaleTimeString()),
    datasets: [
      {
        label: 'Response Time (ms)',
        data: data.responseTime.map((d) => d.value),
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        tension: 0.4,
      },
    ],
  };

  const endpointData = {
    labels: Object.keys(data.requestsByEndpoint),
    datasets: [
      {
        label: 'Requests by Endpoint',
        data: Object.values(data.requestsByEndpoint),
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

  const statusCodeData = {
    labels: Object.keys(data.statusCodeDistribution),
    datasets: [
      {
        label: 'Status Codes',
        data: Object.values(data.statusCodeDistribution),
        backgroundColor: [
          'rgba(75, 192, 192, 0.6)',
          'rgba(255, 206, 86, 0.6)',
          'rgba(255, 99, 132, 0.6)',
        ],
      },
    ],
  };

  return (
    <div className="dashboard">
      <h1>Real-time Dashboard</h1>

      <div className="metrics-grid">
        <div className="metric-card">
          <h3>Active Users</h3>
          <div className="metric-value">{data.activeUsers}</div>
        </div>

        <div className="metric-card">
          <h3>Requests/sec</h3>
          <div className="metric-value">{data.requestsPerSecond.toFixed(2)}</div>
        </div>

        <div className="metric-card">
          <h3>Error Rate</h3>
          <div className="metric-value">{(data.errorRate * 100).toFixed(2)}%</div>
        </div>
      </div>

      <div className="charts-grid">
        <div className="chart-container">
          <h3>Response Time</h3>
          <Line data={responseTimeData} options={{ responsive: true, maintainAspectRatio: false }} />
        </div>

        <div className="chart-container">
          <h3>Requests by Endpoint</h3>
          <Bar data={endpointData} options={{ responsive: true, maintainAspectRatio: false }} />
        </div>

        <div className="chart-container">
          <h3>Status Code Distribution</h3>
          <Pie data={statusCodeData} options={{ responsive: true, maintainAspectRatio: false }} />
        </div>
      </div>
    </div>
  );
};

export default RealtimeDashboard;
