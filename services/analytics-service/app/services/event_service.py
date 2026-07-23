from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func
from ..models.event import Event

class EventService:
    @staticmethod
    def create_event(db: Session, event_data: dict):
        event = Event(**event_data)
        db.add(event)
        db.commit()
        db.refresh(event)
        return event

    @staticmethod
    def get_user_events(db: Session, user_id: str, limit: int = 100):
        return db.query(Event).filter(Event.user_id == user_id).limit(limit).all()

    @staticmethod
    def get_event_count(db: Session, start_date: datetime = None, end_date: datetime = None):
        query = db.query(func.count(Event.id))

        if start_date:
            query = query.filter(Event.timestamp >= start_date)
        if end_date:
            query = query.filter(Event.timestamp <= end_date)

        return query.scalar()

    @staticmethod
    def get_daily_stats(db: Session, days: int = 7):
        start_date = datetime.utcnow() - timedelta(days=days)

        stats = db.query(
            func.date(Event.timestamp).label('date'),
            func.count(Event.id).label('count')
        ).filter(
            Event.timestamp >= start_date
        ).group_by(
            func.date(Event.timestamp)
        ).all()

        return [{"date": str(s.date), "count": s.count} for s in stats]

    @staticmethod
    def get_top_events(db: Session, limit: int = 10):
        top_events = db.query(
            Event.event_name,
            func.count(Event.id).label('count')
        ).group_by(
            Event.event_name
        ).order_by(
            func.count(Event.id).desc()
        ).limit(limit).all()

        return [{"event_name": e.event_name, "count": e.count} for e in top_events]
