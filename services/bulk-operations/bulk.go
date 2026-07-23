package bulk

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
)

type BulkOperation struct {
	db *sql.DB
}

func NewBulkOperation(db *sql.DB) *BulkOperation {
	return &BulkOperation{db: db}
}

func (b *BulkOperation) BulkInsert(ctx context.Context, table string, columns []string, values [][]interface{}) error {
	if len(values) == 0 {
		return nil
	}

	placeholders := make([]string, len(values))
	args := make([]interface{}, 0, len(values)*len(columns))

	for i, row := range values {
		rowPlaceholders := make([]string, len(columns))
		for j := range columns {
			rowPlaceholders[j] = fmt.Sprintf("$%d", i*len(columns)+j+1)
		}
		placeholders[i] = fmt.Sprintf("(%s)", strings.Join(rowPlaceholders, ", "))
		args = append(args, row...)
	}

	query := fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES %s",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
	)

	_, err := b.db.ExecContext(ctx, query, args...)
	return err
}

func (b *BulkOperation) BulkUpdate(ctx context.Context, table string, updates map[string]interface{}, ids []string) error {
	if len(ids) == 0 {
		return nil
	}

	setClauses := make([]string, 0, len(updates))
	args := make([]interface{}, 0, len(updates)+len(ids))
	argIndex := 1

	for column, value := range updates {
		setClauses = append(setClauses, fmt.Sprintf("%s = $%d", column, argIndex))
		args = append(args, value)
		argIndex++
	}

	placeholders := make([]string, len(ids))
	for i, id := range ids {
		placeholders[i] = fmt.Sprintf("$%d", argIndex)
		args = append(args, id)
		argIndex++
	}

	query := fmt.Sprintf(
		"UPDATE %s SET %s WHERE id IN (%s)",
		table,
		strings.Join(setClauses, ", "),
		strings.Join(placeholders, ", "),
	)

	_, err := b.db.ExecContext(ctx, query, args...)
	return err
}

func (b *BulkOperation) BulkDelete(ctx context.Context, table string, ids []string) error {
	if len(ids) == 0 {
		return nil
	}

	placeholders := make([]string, len(ids))
	args := make([]interface{}, len(ids))

	for i, id := range ids {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = id
	}

	query := fmt.Sprintf(
		"DELETE FROM %s WHERE id IN (%s)",
		table,
		strings.Join(placeholders, ", "),
	)

	_, err := b.db.ExecContext(ctx, query, args...)
	return err
}

func (b *BulkOperation) BulkUpsert(ctx context.Context, table string, columns []string, values [][]interface{}, conflictColumn string) error {
	if len(values) == 0 {
		return nil
	}

	placeholders := make([]string, len(values))
	args := make([]interface{}, 0, len(values)*len(columns))

	for i, row := range values {
		rowPlaceholders := make([]string, len(columns))
		for j := range columns {
			rowPlaceholders[j] = fmt.Sprintf("$%d", i*len(columns)+j+1)
		}
		placeholders[i] = fmt.Sprintf("(%s)", strings.Join(rowPlaceholders, ", "))
		args = append(args, row...)
	}

	updateClauses := make([]string, 0, len(columns))
	for _, column := range columns {
		if column != conflictColumn {
			updateClauses = append(updateClauses, fmt.Sprintf("%s = EXCLUDED.%s", column, column))
		}
	}

	query := fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO UPDATE SET %s",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		conflictColumn,
		strings.Join(updateClauses, ", "),
	)

	_, err := b.db.ExecContext(ctx, query, args...)
	return err
}
