from pydantic import BaseModel, validator
from typing import Optional, Dict, Any
from datetime import datetime

class EventValidator(BaseModel):
    user_id: str
    event_type: str
    event_name: str
    properties: Optional[Dict[str, Any]] = {}
    session_id: Optional[str] = None

    @validator('user_id')
    def validate_user_id(cls, v):
        if not v or len(v) < 1:
            raise ValueError('User ID is required')
        return v

    @validator('event_type')
    def validate_event_type(cls, v):
        allowed_types = ['click', 'page_view', 'form_submit', 'api_call', 'custom']
        if v not in allowed_types:
            raise ValueError(f'Event type must be one of: {", ".join(allowed_types)}')
        return v

class StatsQueryValidator(BaseModel):
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    user_id: Optional[str] = None

    @validator('end_date')
    def validate_date_range(cls, v, values):
        if v and 'start_date' in values and values['start_date']:
            if v < values['start_date']:
                raise ValueError('End date must be after start date')
        return v
