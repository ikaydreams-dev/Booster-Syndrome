from pydantic import BaseModel, EmailStr, validator, Field
from typing import Optional, Dict, Any
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    first_name: Optional[str] = None
    last_name: Optional[str] = None

    @validator('username')
    def username_alphanumeric(cls, v):
        assert v.replace('_', '').replace('-', '').isalnum(), 'must be alphanumeric'
        return v

    @validator('password')
    def password_strength(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError('must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('must contain at least one uppercase letter')
        if not any(char.islower() for char in v):
            raise ValueError('must contain at least one lowercase letter')
        return v

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None

class EventCreate(BaseModel):
    user_id: str
    event_name: str = Field(..., min_length=1)
    event_type: str
    properties: Dict[str, Any] = Field(default_factory=dict)

    @validator('event_type')
    def event_type_valid(cls, v):
        valid_types = ['page_view', 'click', 'conversion', 'custom']
        if v not in valid_types:
            raise ValueError(f'must be one of {valid_types}')
        return v

class SessionCreate(BaseModel):
    user_id: str
    device_type: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RegisterRequest(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)

    @validator('password')
    def password_strength(cls, v):
        if not any(char.isdigit() for char in v):
            raise ValueError('must contain at least one digit')
        if not any(char.isupper() for char in v):
            raise ValueError('must contain at least one uppercase letter')
        return v

class AnalyticsQuery(BaseModel):
    start_date: datetime
    end_date: datetime
    event_types: Optional[list[str]] = None
    user_ids: Optional[list[str]] = None

    @validator('end_date')
    def end_after_start(cls, v, values):
        if 'start_date' in values and v < values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v
