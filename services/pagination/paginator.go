package pagination

import (
	"math"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Pagination struct {
	Page       int         `json:"page"`
	PageSize   int         `json:"pageSize"`
	TotalItems int64       `json:"totalItems"`
	TotalPages int         `json:"totalPages"`
	HasNext    bool        `json:"hasNext"`
	HasPrev    bool        `json:"hasPrev"`
	Data       interface{} `json:"data"`
}

type PaginationParams struct {
	Page     int
	PageSize int
	Offset   int
}

func GetPaginationParams(c *gin.Context) PaginationParams {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))

	if page < 1 {
		page = 1
	}

	if pageSize < 1 {
		pageSize = 10
	}

	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize

	return PaginationParams{
		Page:     page,
		PageSize: pageSize,
		Offset:   offset,
	}
}

func NewPagination(page, pageSize int, totalItems int64, data interface{}) *Pagination {
	totalPages := int(math.Ceil(float64(totalItems) / float64(pageSize)))

	return &Pagination{
		Page:       page,
		PageSize:   pageSize,
		TotalItems: totalItems,
		TotalPages: totalPages,
		HasNext:    page < totalPages,
		HasPrev:    page > 1,
		Data:       data,
	}
}
