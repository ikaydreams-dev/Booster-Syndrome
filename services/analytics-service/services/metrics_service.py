from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from uuid import UUID
import asyncpg

class MetricsService:
    """Service for calculating and aggregating analytics metrics"""

    def __init__(self, db_pool: asyncpg.Pool):
        self.db = db_pool

    async def get_event_count(
        self,
        start_date: datetime,
        end_date: datetime,
        event_type: Optional[str] = None
    ) -> int:
        """Get total event count for date range"""
        query = """
            SELECT COUNT(*) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
        """
        params = [start_date, end_date]

        if event_type:
            query += " AND event_type = $3"
            params.append(event_type)

        result = await self.db.fetchrow(query, *params)
        return result['count']

    async def get_unique_users(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> int:
        """Get count of unique users in date range"""
        query = """
            SELECT COUNT(DISTINCT user_id) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
            AND user_id IS NOT NULL
        """
        result = await self.db.fetchrow(query, start_date, end_date)
        return result['count']

    async def get_top_events(
        self,
        start_date: datetime,
        end_date: datetime,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get top event types by count"""
        query = """
            SELECT event_type, COUNT(*) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
            GROUP BY event_type
            ORDER BY count DESC
            LIMIT $3
        """
        rows = await self.db.fetch(query, start_date, end_date, limit)
        return [dict(row) for row in rows]

    async def get_events_by_country(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> List[Dict[str, Any]]:
        """Get event distribution by country"""
        query = """
            SELECT country, COUNT(*) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
            AND country IS NOT NULL
            GROUP BY country
            ORDER BY count DESC
        """
        rows = await self.db.fetch(query, start_date, end_date)
        return [dict(row) for row in rows]

    async def get_device_breakdown(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> Dict[str, int]:
        """Get breakdown of events by device type"""
        query = """
            SELECT device_type, COUNT(*) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
            AND device_type IS NOT NULL
            GROUP BY device_type
        """
        rows = await self.db.fetch(query, start_date, end_date)
        return {row['device_type']: row['count'] for row in rows}

    async def get_hourly_distribution(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> List[Dict[str, Any]]:
        """Get event distribution by hour of day"""
        query = """
            SELECT EXTRACT(HOUR FROM timestamp) as hour,
                   COUNT(*) as count
            FROM events
            WHERE timestamp >= $1 AND timestamp <= $2
            GROUP BY hour
            ORDER BY hour
        """
        rows = await self.db.fetch(query, start_date, end_date)
        return [{'hour': int(row['hour']), 'count': row['count']} for row in rows]

    async def calculate_retention(
        self,
        cohort_date: datetime,
        days: int = 30
    ) -> List[Dict[str, Any]]:
        """Calculate user retention for a cohort"""
        # Get users who signed up on cohort_date
        cohort_users_query = """
            SELECT DISTINCT user_id
            FROM events
            WHERE DATE(timestamp) = DATE($1)
            AND event_type = 'signup'
        """
        cohort_users = await self.db.fetch(cohort_users_query, cohort_date)
        cohort_user_ids = [row['user_id'] for row in cohort_users]

        if not cohort_user_ids:
            return []

        retention_data = []

        for day in range(days):
            check_date = cohort_date + timedelta(days=day)
            active_query = """
                SELECT COUNT(DISTINCT user_id) as count
                FROM events
                WHERE DATE(timestamp) = DATE($1)
                AND user_id = ANY($2)
            """
            result = await self.db.fetchrow(active_query, check_date, cohort_user_ids)
            retention_rate = (result['count'] / len(cohort_user_ids)) * 100

            retention_data.append({
                'day': day,
                'active_users': result['count'],
                'retention_rate': round(retention_rate, 2)
            })

        return retention_data

    async def get_conversion_rate(
        self,
        funnel_steps: List[str],
        start_date: datetime,
        end_date: datetime
    ) -> float:
        """Calculate conversion rate through a funnel"""
        if len(funnel_steps) < 2:
            return 0.0

        # Get users who completed first step
        first_step_query = """
            SELECT DISTINCT user_id
            FROM events
            WHERE event_type = $1
            AND timestamp >= $2 AND timestamp <= $3
        """
        first_step_users = await self.db.fetch(
            first_step_query,
            funnel_steps[0],
            start_date,
            end_date
        )
        first_count = len(first_step_users)

        if first_count == 0:
            return 0.0

        # Get users who completed last step
        last_step_query = """
            SELECT DISTINCT user_id
            FROM events
            WHERE event_type = $1
            AND timestamp >= $2 AND timestamp <= $3
        """
        last_step_users = await self.db.fetch(
            last_step_query,
            funnel_steps[-1],
            start_date,
            end_date
        )
        last_count = len(last_step_users)

        conversion_rate = (last_count / first_count) * 100
        return round(conversion_rate, 2)
