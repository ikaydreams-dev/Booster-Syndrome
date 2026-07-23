from typing import Generic, TypeVar, List
from pydantic import BaseModel
from math import ceil

T = TypeVar('T')

class PaginationParams(BaseModel):
    page: int = 1
    page_size: int = 10

    def __init__(self, page: int = 1, page_size: int = 10):
        super().__init__(page=page, page_size=page_size)

        if self.page < 1:
            self.page = 1

        if self.page_size < 1:
            self.page_size = 10

        if self.page_size > 100:
            self.page_size = 100

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size

class PaginatedResponse(BaseModel, Generic[T]):
    page: int
    page_size: int
    total_items: int
    total_pages: int
    has_next: bool
    has_prev: bool
    data: List[T]

    class Config:
        arbitrary_types_allowed = True

def paginate(data: List[T], total_items: int, params: PaginationParams) -> PaginatedResponse[T]:
    total_pages = ceil(total_items / params.page_size)

    return PaginatedResponse(
        page=params.page,
        page_size=params.page_size,
        total_items=total_items,
        total_pages=total_pages,
        has_next=params.page < total_pages,
        has_prev=params.page > 1,
        data=data
    )

def extract_pagination_params(page: int = 1, page_size: int = 10) -> PaginationParams:
    return PaginationParams(page=page, page_size=page_size)
