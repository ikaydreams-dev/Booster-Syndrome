use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct Span {
    pub trace_id: String,
    pub span_id: String,
    pub parent_span_id: Option<String>,
    pub name: String,
    pub start_time: u64,
    pub end_time: Option<u64>,
    pub attributes: HashMap<String, String>,
    pub events: Vec<SpanEvent>,
}

pub struct SpanEvent {
    pub name: String,
    pub timestamp: u64,
    pub attributes: HashMap<String, String>,
}

impl Span {
    pub fn new(name: String, trace_id: String) -> Self {
        let span_id = Self::generate_span_id();
        let start_time = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;

        Self {
            trace_id,
            span_id,
            parent_span_id: None,
            name,
            start_time,
            end_time: None,
            attributes: HashMap::new(),
            events: Vec::new(),
        }
    }

    pub fn with_parent(name: String, trace_id: String, parent_span_id: String) -> Self {
        let mut span = Self::new(name, trace_id);
        span.parent_span_id = Some(parent_span_id);
        span
    }

    pub fn set_attribute(&mut self, key: String, value: String) {
        self.attributes.insert(key, value);
    }

    pub fn add_event(&mut self, name: String, attributes: HashMap<String, String>) {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;

        self.events.push(SpanEvent {
            name,
            timestamp,
            attributes,
        });
    }

    pub fn end(&mut self) {
        self.end_time = Some(
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos() as u64,
        );
    }

    fn generate_span_id() -> String {
        use std::time::SystemTime;
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        format!("{:x}", now)
    }
}

pub struct Tracer {
    service_name: String,
}

impl Tracer {
    pub fn new(service_name: String) -> Self {
        Self { service_name }
    }

    pub fn start_span(&self, name: String) -> Span {
        let trace_id = self.generate_trace_id();
        let mut span = Span::new(name, trace_id);
        span.set_attribute("service.name".to_string(), self.service_name.clone());
        span
    }

    pub fn start_child_span(&self, name: String, parent: &Span) -> Span {
        let mut span = Span::with_parent(
            name,
            parent.trace_id.clone(),
            parent.span_id.clone(),
        );
        span.set_attribute("service.name".to_string(), self.service_name.clone());
        span
    }

    fn generate_trace_id(&self) -> String {
        use std::time::SystemTime;
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        format!("{:x}", now)
    }
}

// Example usage
pub fn example_traced_operation() {
    let tracer = Tracer::new("booster-service".to_string());
    
    let mut root_span = tracer.start_span("process_request".to_string());
    root_span.set_attribute("http.method".to_string(), "GET".to_string());
    root_span.set_attribute("http.url".to_string(), "/api/users".to_string());
    
    let mut db_span = tracer.start_child_span("database_query".to_string(), &root_span);
    db_span.set_attribute("db.system".to_string(), "postgresql".to_string());
    db_span.add_event("query_executed".to_string(), HashMap::new());
    db_span.end();
    
    root_span.end();
}
