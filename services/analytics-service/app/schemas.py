from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any
from uuid import UUID

class EventCreate(BaseModel):
    user_id: UUID
    event_type: str
    event_name: str
    properties: Optional[Dict[str, Any]] = {}
    session_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class EventResponse(BaseModel):
    id: UUID
    user_id: UUID
    event_type: str
    event_name: str
    properties: Dict[str, Any]
    timestamp: datetime
    session_id: Optional[str]

    class Config:
        from_attributes = True
