from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from uuid import UUID, uuid4

class EventBase(BaseModel):
    user_id: Optional[UUID] = None
    session_id: Optional[UUID] = None
    event_type: str
    event_name: str
    properties: Optional[Dict[str, Any]] = None
    page_url: Optional[str] = None
    referrer: Optional[str] = None
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None
    country: Optional[str] = None
    city: Optional[str] = None
    device_type: Optional[str] = None
    browser: Optional[str] = None
    os: Optional[str] = None

class EventCreate(EventBase):
    pass

class EventResponse(EventBase):
    id: UUID = Field(default_factory=uuid4)
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

class EventAnalytics(BaseModel):
    total_events: int
    unique_users: int
    event_types: Dict[str, int]
    top_pages: list[Dict[str, Any]]
    devices: Dict[str, int]
    browsers: Dict[str, int]

class FunnelStep(BaseModel):
    step_name: str
    count: int
    conversion_rate: float

class FunnelAnalysis(BaseModel):
    steps: list[FunnelStep]
    overall_conversion: float
    drop_off_points: list[str]
