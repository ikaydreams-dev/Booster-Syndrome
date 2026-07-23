from sqlalchemy import Column, String, Integer, DateTime, JSON
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from ..database import Base

class Event(Base):
    __tablename__ = "events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    event_type = Column(String(100), nullable=False, index=True)
    event_name = Column(String(200), nullable=False)
    properties = Column(JSON, default={})
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    session_id = Column(String(100))
    ip_address = Column(String(45))
    user_agent = Column(String(500))
