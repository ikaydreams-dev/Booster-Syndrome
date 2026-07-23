from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
import pandas as pd

from ..database import get_db
from ..models.event import Event

router = APIRouter()

@router.get("/top-events")
async def get_top_events(limit: int = 10, db: Session = Depends(get_db)):
    top_events = db.query(
        Event.event_name,
        func.count(Event.id).label('count')
    ).group_by(
        Event.event_name
    ).order_by(
        func.count(Event.id).desc()
    ).limit(limit).all()

    return [{"event_name": e.event_name, "count": e.count} for e in top_events]

@router.get("/user-activity/{user_id}")
async def get_user_activity(user_id: str, db: Session = Depends(get_db)):
    events = db.query(Event).filter(Event.user_id == user_id).all()

    if not events:
        return {"user_id": user_id, "total_events": 0, "events": []}

    return {
        "user_id": user_id,
        "total_events": len(events),
        "first_seen": min(e.timestamp for e in events),
        "last_seen": max(e.timestamp for e in events),
    }
