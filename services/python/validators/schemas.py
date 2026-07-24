from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime

class UserCreateSchema(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    
    @validator('password')
    def validate_password(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain number')
        return v

class UserUpdateSchema(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8)
    
    @validator('password')
    def validate_password(cls, v):
        if v is None:
            return v
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain number')
        return v

class UserResponseSchema(BaseModel):
    id: int
    email: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class PostCreateSchema(BaseModel):
    title: str = Field(..., min_length=3, max_length=255)
    content: str = Field(..., min_length=10)
    user_id: int
    published: bool = False

class PostUpdateSchema(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=255)
    content: Optional[str] = Field(None, min_length=10)
    published: Optional[bool] = None

class PostResponseSchema(BaseModel):
    id: int
    title: str
    content: str
    published: bool
    user_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class CommentCreateSchema(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000)
    post_id: int
    user_id: int

class CommentUpdateSchema(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000)

class CommentResponseSchema(BaseModel):
    id: int
    content: str
    post_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
