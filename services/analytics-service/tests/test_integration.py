import pytest
import httpx
from fastapi.testclient import TestClient

BASE_URL = "http://localhost:8001"

class TestAnalyticsIntegration:

    @pytest.mark.asyncio
    async def test_track_event(self):
        """Test event tracking endpoint"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{BASE_URL}/api/v1/events",
                json={
                    "user_id": "user123",
                    "event_type": "page_view",
                    "properties": {
                        "page": "/home",
                        "referrer": "google"
                    }
                }
            )
            assert response.status_code == 201
            assert "event_id" in response.json()

    @pytest.mark.asyncio
    async def test_get_analytics(self):
        """Test analytics retrieval"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{BASE_URL}/api/v1/analytics",
                params={"user_id": "user123"}
            )
            assert response.status_code == 200
            assert "events" in response.json()

    @pytest.mark.asyncio
    async def test_aggregate_metrics(self):
        """Test metric aggregation"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{BASE_URL}/api/v1/metrics/aggregate",
                params={
                    "metric": "page_views",
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31"
                }
            )
            assert response.status_code == 200
            assert "total" in response.json()

    @pytest.mark.asyncio
    async def test_user_funnel(self):
        """Test user funnel analysis"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{BASE_URL}/api/v1/funnel",
                json={
                    "steps": ["signup", "activation", "purchase"],
                    "start_date": "2024-01-01",
                    "end_date": "2024-01-31"
                }
            )
            assert response.status_code == 200
            assert "conversion_rate" in response.json()

    @pytest.mark.asyncio
    async def test_cohort_analysis(self):
        """Test cohort analysis"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{BASE_URL}/api/v1/cohorts",
                params={"cohort_date": "2024-01-01"}
            )
            assert response.status_code == 200
            assert "retention" in response.json()
