package permissions

import (
	"errors"
	"sync"
)

type Permission string

const (
	CreateUser    Permission = "user:create"
	ReadUser      Permission = "user:read"
	UpdateUser    Permission = "user:update"
	DeleteUser    Permission = "user:delete"
	ManageRoles   Permission = "roles:manage"
	ViewAnalytics Permission = "analytics:view"
	ManageSystem  Permission = "system:manage"
)

type Resource struct {
	Type string
	ID   string
}

type PermissionRule struct {
	Permission Permission
	Resource   *Resource
	Condition  func(userId string, resource *Resource) bool
}

type PermissionSystem struct {
	mu          sync.RWMutex
	permissions map[string][]Permission
	rules       []PermissionRule
}

func NewPermissionSystem() *PermissionSystem {
	return &PermissionSystem{
		permissions: make(map[string][]Permission),
		rules:       make([]PermissionRule, 0),
	}
}

func (ps *PermissionSystem) Grant(userId string, permission Permission) {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	if ps.permissions[userId] == nil {
		ps.permissions[userId] = make([]Permission, 0)
	}

	ps.permissions[userId] = append(ps.permissions[userId], permission)
}

func (ps *PermissionSystem) Revoke(userId string, permission Permission) {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	perms := ps.permissions[userId]
	if perms == nil {
		return
	}

	filtered := make([]Permission, 0)
	for _, p := range perms {
		if p != permission {
			filtered = append(filtered, p)
		}
	}

	ps.permissions[userId] = filtered
}

func (ps *PermissionSystem) Has(userId string, permission Permission) bool {
	ps.mu.RLock()
	defer ps.mu.RUnlock()

	perms := ps.permissions[userId]
	if perms == nil {
		return false
	}

	for _, p := range perms {
		if p == permission {
			return true
		}
	}

	return false
}

func (ps *PermissionSystem) HasAny(userId string, permissions []Permission) bool {
	for _, permission := range permissions {
		if ps.Has(userId, permission) {
			return true
		}
	}

	return false
}

func (ps *PermissionSystem) HasAll(userId string, permissions []Permission) bool {
	for _, permission := range permissions {
		if !ps.Has(userId, permission) {
			return false
		}
	}

	return true
}

func (ps *PermissionSystem) GetPermissions(userId string) []Permission {
	ps.mu.RLock()
	defer ps.mu.RUnlock()

	perms := ps.permissions[userId]
	if perms == nil {
		return []Permission{}
	}

	result := make([]Permission, len(perms))
	copy(result, perms)

	return result
}

func (ps *PermissionSystem) AddRule(rule PermissionRule) {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	ps.rules = append(ps.rules, rule)
}

func (ps *PermissionSystem) Check(userId string, permission Permission, resource *Resource) error {
	if !ps.Has(userId, permission) {
		return errors.New("permission denied")
	}

	ps.mu.RLock()
	defer ps.mu.RUnlock()

	for _, rule := range ps.rules {
		if rule.Permission == permission && rule.Resource != nil {
			if resource == nil || !rule.Condition(userId, resource) {
				return errors.New("permission denied by rule")
			}
		}
	}

	return nil
}

func (ps *PermissionSystem) GrantMultiple(userId string, permissions []Permission) {
	for _, permission := range permissions {
		ps.Grant(userId, permission)
	}
}

func (ps *PermissionSystem) RevokeAll(userId string) {
	ps.mu.Lock()
	defer ps.mu.Unlock()

	delete(ps.permissions, userId)
}
