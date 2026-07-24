use std::collections::HashMap;
use std::sync::{Arc, Mutex, RwLock};
use std::time::{Duration, SystemTime};

pub struct Database {
    tables: RwLock<HashMap<String, Table>>,
}

pub struct Table {
    name: String,
    columns: Vec<Column>,
    rows: Vec<Row>,
    indexes: HashMap<String, Index>,
}

pub struct Column {
    name: String,
    data_type: DataType,
    nullable: bool,
    default_value: Option<Value>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum DataType {
    Integer,
    Float,
    String,
    Boolean,
    DateTime,
    Blob,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Integer(i64),
    Float(f64),
    String(String),
    Boolean(bool),
    DateTime(SystemTime),
    Blob(Vec<u8>),
    Null,
}

pub struct Row {
    id: u64,
    values: HashMap<String, Value>,
}

pub struct Index {
    column: String,
    entries: HashMap<Value, Vec<u64>>,
}

impl Database {
    pub fn new() -> Self {
        Database {
            tables: RwLock::new(HashMap::new()),
        }
    }

    pub fn create_table(&self, name: String, columns: Vec<Column>) -> Result<(), String> {
        let mut tables = self.tables.write().unwrap();

        if tables.contains_key(&name) {
            return Err(format!("Table {} already exists", name));
        }

        tables.insert(name.clone(), Table {
            name,
            columns,
            rows: Vec::new(),
            indexes: HashMap::new(),
        });

        Ok(())
    }

    pub fn drop_table(&self, name: &str) -> Result<(), String> {
        let mut tables = self.tables.write().unwrap();

        if !tables.contains_key(name) {
            return Err(format!("Table {} does not exist", name));
        }

        tables.remove(name);
        Ok(())
    }

    pub fn insert(&self, table_name: &str, values: HashMap<String, Value>) -> Result<u64, String> {
        let mut tables = self.tables.write().unwrap();
        let table = tables.get_mut(table_name)
            .ok_or_else(|| format!("Table {} not found", table_name))?;

        let id = table.rows.len() as u64;
        let row = Row { id, values };

        table.rows.push(row);
        Ok(id)
    }

    pub fn select(&self, table_name: &str, filter: Option<Filter>) -> Result<Vec<Row>, String> {
        let tables = self.tables.read().unwrap();
        let table = tables.get(table_name)
            .ok_or_else(|| format!("Table {} not found", table_name))?;

        let mut results = Vec::new();

        for row in &table.rows {
            if let Some(ref f) = filter {
                if f.matches(row) {
                    results.push(row.clone());
                }
            } else {
                results.push(row.clone());
            }
        }

        Ok(results)
    }

    pub fn update(&self, table_name: &str, filter: Filter, updates: HashMap<String, Value>) -> Result<usize, String> {
        let mut tables = self.tables.write().unwrap();
        let table = tables.get_mut(table_name)
            .ok_or_else(|| format!("Table {} not found", table_name))?;

        let mut count = 0;

        for row in &mut table.rows {
            if filter.matches(row) {
                for (key, value) in &updates {
                    row.values.insert(key.clone(), value.clone());
                }
                count += 1;
            }
        }

        Ok(count)
    }

    pub fn delete(&self, table_name: &str, filter: Filter) -> Result<usize, String> {
        let mut tables = self.tables.write().unwrap();
        let table = tables.get_mut(table_name)
            .ok_or_else(|| format!("Table {} not found", table_name))?;

        let original_len = table.rows.len();
        table.rows.retain(|row| !filter.matches(row));

        Ok(original_len - table.rows.len())
    }

    pub fn create_index(&self, table_name: &str, column: String) -> Result<(), String> {
        let mut tables = self.tables.write().unwrap();
        let table = tables.get_mut(table_name)
            .ok_or_else(|| format!("Table {} not found", table_name))?;

        let mut entries = HashMap::new();

        for row in &table.rows {
            if let Some(value) = row.values.get(&column) {
                entries.entry(value.clone())
                    .or_insert_with(Vec::new)
                    .push(row.id);
            }
        }

        table.indexes.insert(column.clone(), Index {
            column,
            entries,
        });

        Ok(())
    }
}

impl Clone for Row {
    fn clone(&self) -> Self {
        Row {
            id: self.id,
            values: self.values.clone(),
        }
    }
}

pub struct Filter {
    conditions: Vec<Condition>,
}

pub struct Condition {
    column: String,
    operator: Operator,
    value: Value,
}

#[derive(Debug, Clone)]
pub enum Operator {
    Equal,
    NotEqual,
    GreaterThan,
    LessThan,
    GreaterThanOrEqual,
    LessThanOrEqual,
    Like,
}

impl Filter {
    pub fn new() -> Self {
        Filter {
            conditions: Vec::new(),
        }
    }

    pub fn add_condition(&mut self, column: String, operator: Operator, value: Value) {
        self.conditions.push(Condition {
            column,
            operator,
            value,
        });
    }

    pub fn matches(&self, row: &Row) -> bool {
        for condition in &self.conditions {
            if let Some(row_value) = row.values.get(&condition.column) {
                if !condition.matches(row_value) {
                    return false;
                }
            } else {
                return false;
            }
        }
        true
    }
}

impl Condition {
    pub fn matches(&self, value: &Value) -> bool {
        match self.operator {
            Operator::Equal => value == &self.value,
            Operator::NotEqual => value != &self.value,
            Operator::GreaterThan => self.compare_values(value, &self.value) > 0,
            Operator::LessThan => self.compare_values(value, &self.value) < 0,
            Operator::GreaterThanOrEqual => self.compare_values(value, &self.value) >= 0,
            Operator::LessThanOrEqual => self.compare_values(value, &self.value) <= 0,
            Operator::Like => self.like_match(value),
        }
    }

    fn compare_values(&self, a: &Value, b: &Value) -> i32 {
        match (a, b) {
            (Value::Integer(x), Value::Integer(y)) => x.cmp(y) as i32,
            (Value::Float(x), Value::Float(y)) => {
                if x < y { -1 } else if x > y { 1 } else { 0 }
            }
            (Value::String(x), Value::String(y)) => x.cmp(y) as i32,
            _ => 0,
        }
    }

    fn like_match(&self, value: &Value) -> bool {
        if let (Value::String(val), Value::String(pattern)) = (value, &self.value) {
            val.contains(pattern)
        } else {
            false
        }
    }
}

pub struct Transaction {
    operations: Vec<Operation>,
    state: TransactionState,
}

pub enum Operation {
    Insert { table: String, values: HashMap<String, Value> },
    Update { table: String, filter: Filter, updates: HashMap<String, Value> },
    Delete { table: String, filter: Filter },
}

pub enum TransactionState {
    Active,
    Committed,
    RolledBack,
}

impl Transaction {
    pub fn new() -> Self {
        Transaction {
            operations: Vec::new(),
            state: TransactionState::Active,
        }
    }

    pub fn add_operation(&mut self, operation: Operation) {
        self.operations.push(operation);
    }

    pub fn commit(&mut self, db: &Database) -> Result<(), String> {
        for operation in &self.operations {
            match operation {
                Operation::Insert { table, values } => {
                    db.insert(table, values.clone())?;
                }
                Operation::Update { table, filter, updates } => {
                    db.update(table, filter.clone(), updates.clone())?;
                }
                Operation::Delete { table, filter } => {
                    db.delete(table, filter.clone())?;
                }
            }
        }

        self.state = TransactionState::Committed;
        Ok(())
    }

    pub fn rollback(&mut self) {
        self.state = TransactionState::RolledBack;
        self.operations.clear();
    }
}

impl Clone for Filter {
    fn clone(&self) -> Self {
        Filter {
            conditions: self.conditions.iter().map(|c| Condition {
                column: c.column.clone(),
                operator: c.operator.clone(),
                value: c.value.clone(),
            }).collect(),
        }
    }
}

pub struct QueryBuilder {
    table: String,
    columns: Vec<String>,
    filter: Option<Filter>,
    order_by: Vec<(String, OrderDirection)>,
    limit: Option<usize>,
    offset: Option<usize>,
}

pub enum OrderDirection {
    Asc,
    Desc,
}

impl QueryBuilder {
    pub fn new(table: String) -> Self {
        QueryBuilder {
            table,
            columns: vec!["*".to_string()],
            filter: None,
            order_by: Vec::new(),
            limit: None,
            offset: None,
        }
    }

    pub fn select(mut self, columns: Vec<String>) -> Self {
        self.columns = columns;
        self
    }

    pub fn filter(mut self, filter: Filter) -> Self {
        self.filter = Some(filter);
        self
    }

    pub fn order_by(mut self, column: String, direction: OrderDirection) -> Self {
        self.order_by.push((column, direction));
        self
    }

    pub fn limit(mut self, limit: usize) -> Self {
        self.limit = Some(limit);
        self
    }

    pub fn offset(mut self, offset: usize) -> Self {
        self.offset = Some(offset);
        self
    }

    pub fn execute(&self, db: &Database) -> Result<Vec<Row>, String> {
        let mut results = db.select(&self.table, self.filter.clone())?;

        if let Some(limit) = self.limit {
            results.truncate(limit);
        }

        Ok(results)
    }
}

pub struct ConnectionPool {
    connections: Mutex<Vec<Arc<Database>>>,
    max_size: usize,
}

impl ConnectionPool {
    pub fn new(max_size: usize) -> Self {
        ConnectionPool {
            connections: Mutex::new(Vec::new()),
            max_size,
        }
    }

    pub fn get_connection(&self) -> Arc<Database> {
        let mut connections = self.connections.lock().unwrap();

        if let Some(conn) = connections.pop() {
            conn
        } else {
            Arc::new(Database::new())
        }
    }

    pub fn release_connection(&self, conn: Arc<Database>) {
        let mut connections = self.connections.lock().unwrap();

        if connections.len() < self.max_size {
            connections.push(conn);
        }
    }
}
