from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ..database import get_db
from ..models.event import Event
from ..schemas import EventCreate, EventResponse

router = APIRouter()

@router.post("/events", response_model=EventResponse)
async def track_event(event: EventCreate, db: Session = Depends(get_db)):
    db_event = Event(**event.dict())
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event

@router.get("/events/{user_id}", response_model=List[EventResponse])
async def get_user_events(user_id: str, db: Session = Depends(get_db)):
    events = db.query(Event).filter(Event.user_id == user_id).all()
    return events
