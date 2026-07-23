package featureflags

import "sync"

type Flag struct {
	Name        string
	Enabled     bool
	Percentage  int
	UserTargets []string
}

type FlagsManager struct {
	flags map[string]*Flag
	mu    sync.RWMutex
}

func NewFlagsManager() *FlagsManager {
	return &FlagsManager{
		flags: make(map[string]*Flag),
	}
}

func (fm *FlagsManager) CreateFlag(name string, enabled bool) {
	fm.mu.Lock()
	defer fm.mu.Unlock()

	fm.flags[name] = &Flag{
		Name:        name,
		Enabled:     enabled,
		Percentage:  100,
		UserTargets: []string{},
	}
}

func (fm *FlagsManager) IsEnabled(name string, userID string) bool {
	fm.mu.RLock()
	defer fm.mu.RUnlock()

	flag, exists := fm.flags[name]
	if !exists {
		return false
	}

	if !flag.Enabled {
		return false
	}

	for _, target := range flag.UserTargets {
		if target == userID {
			return true
		}
	}

	return flag.Percentage == 100
}

func (fm *FlagsManager) EnableFlag(name string) {
	fm.mu.Lock()
	defer fm.mu.Unlock()

	if flag, exists := fm.flags[name]; exists {
		flag.Enabled = true
	}
}

func (fm *FlagsManager) DisableFlag(name string) {
	fm.mu.Lock()
	defer fm.mu.Unlock()

	if flag, exists := fm.flags[name]; exists {
		flag.Enabled = false
	}
}

func (fm *FlagsManager) GetAllFlags() map[string]*Flag {
	fm.mu.RLock()
	defer fm.mu.RUnlock()

	result := make(map[string]*Flag)
	for k, v := range fm.flags {
		result[k] = v
	}
	return result
}
