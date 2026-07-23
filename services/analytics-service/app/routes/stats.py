from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta

from ..database import get_db
from ..models.event import Event

router = APIRouter()

@router.get("/summary")
async def get_summary(db: Session = Depends(get_db)):
    total_events = db.query(func.count(Event.id)).scalar()
    unique_users = db.query(func.count(func.distinct(Event.user_id))).scalar()

    return {
        "total_events": total_events,
        "unique_users": unique_users,
        "timestamp": datetime.utcnow()
    }

@router.get("/daily")
async def get_daily_stats(days: int = 7, db: Session = Depends(get_db)):
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
