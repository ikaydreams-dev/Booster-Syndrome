package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
)

type HTTPHandler struct {
	service Service
}

type Service interface {
	List(page, perPage int) ([]interface{}, int, error)
	Get(id int) (interface{}, error)
	Create(data map[string]interface{}) (interface{}, error)
	Update(id int, data map[string]interface{}) (interface{}, error)
	Delete(id int) error
}

func NewHTTPHandler(service Service) *HTTPHandler {
	return &HTTPHandler{service: service}
}

func (h *HTTPHandler) List(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	
	perPage, _ := strconv.Atoi(r.URL.Query().Get("per_page"))
	if perPage < 1 {
		perPage = 20
	}
	
	items, total, err := h.service.List(page, perPage)
	if err != nil {
		h.errorResponse(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	response := map[string]interface{}{
		"data": items,
		"pagination": map[string]interface{}{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": (total + perPage - 1) / perPage,
		},
	}
	
	h.jsonResponse(w, response, http.StatusOK)
}

func (h *HTTPHandler) Get(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	
	item, err := h.service.Get(id)
	if err != nil {
		h.errorResponse(w, "Not found", http.StatusNotFound)
		return
	}
	
	h.jsonResponse(w, item, http.StatusOK)
}

func (h *HTTPHandler) Create(w http.ResponseWriter, r *http.Request) {
	var data map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		h.errorResponse(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	
	item, err := h.service.Create(data)
	if err != nil {
		h.errorResponse(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}
	
	h.jsonResponse(w, item, http.StatusCreated)
}

func (h *HTTPHandler) Update(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	
	var data map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		h.errorResponse(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	
	item, err := h.service.Update(id, data)
	if err != nil {
		h.errorResponse(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}
	
	h.jsonResponse(w, item, http.StatusOK)
}

func (h *HTTPHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(r.URL.Query().Get("id"))
	
	if err := h.service.Delete(id); err != nil {
		h.errorResponse(w, "Not found", http.StatusNotFound)
		return
	}
	
	w.WriteHeader(http.StatusNoContent)
}

func (h *HTTPHandler) jsonResponse(w http.ResponseWriter, data interface{}, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *HTTPHandler) errorResponse(w http.ResponseWriter, message string, status int) {
	h.jsonResponse(w, map[string]string{"error": message}, status)
}
