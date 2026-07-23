package dbconnector

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

type PostgresConnector struct {
	db *sql.DB
}

func NewPostgresConnector(host, port, user, password, dbname string) (*PostgresConnector, error) {
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, err
	}

	if err = db.Ping(); err != nil {
		return nil, err
	}

	return &PostgresConnector{db: db}, nil
}

func (pc *PostgresConnector) Query(query string, args ...interface{}) (*sql.Rows, error) {
	return pc.db.Query(query, args...)
}

func (pc *PostgresConnector) Exec(query string, args ...interface{}) (sql.Result, error) {
	return pc.db.Exec(query, args...)
}

func (pc *PostgresConnector) QueryRow(query string, args ...interface{}) *sql.Row {
	return pc.db.QueryRow(query, args...)
}

func (pc *PostgresConnector) Begin() (*sql.Tx, error) {
	return pc.db.Begin()
}

func (pc *PostgresConnector) Close() error {
	return pc.db.Close()
}
