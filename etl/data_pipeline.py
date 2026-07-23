import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from datetime import datetime
import json

class ExtractEvents(beam.DoFn):
    """Extract events from source"""
    def process(self, element):
        try:
            event = json.loads(element)
            yield event
        except Exception as e:
            print(f"Error extracting event: {e}")

class TransformEvent(beam.DoFn):
    """Transform event data"""
    def process(self, event):
        transformed = {
            'event_id': event.get('id'),
            'user_id': event.get('user_id'),
            'event_type': event.get('event_type'),
            'timestamp': event.get('timestamp'),
            'properties': event.get('properties', {}),
            'processed_at': datetime.utcnow().isoformat()
        }

        # Enrich with calculated fields
        transformed['date'] = datetime.fromtimestamp(
            event.get('timestamp', 0) / 1000
        ).date().isoformat()

        transformed['hour'] = datetime.fromtimestamp(
            event.get('timestamp', 0) / 1000
        ).hour

        # Add device category
        user_agent = event.get('user_agent', '').lower()
        if 'mobile' in user_agent:
            transformed['device_category'] = 'mobile'
        elif 'tablet' in user_agent:
            transformed['device_category'] = 'tablet'
        else:
            transformed['device_category'] = 'desktop'

        yield transformed

class FilterValidEvents(beam.DoFn):
    """Filter out invalid events"""
    def process(self, event):
        if event.get('event_id') and event.get('event_type'):
            yield event

class AggregateByUser(beam.DoFn):
    """Aggregate events by user"""
    def process(self, element):
        user_id, events = element

        total_events = len(events)
        event_types = set(e['event_type'] for e in events)

        yield {
            'user_id': user_id,
            'total_events': total_events,
            'unique_event_types': len(event_types),
            'events': events
        }

class FormatForBigQuery(beam.DoFn):
    """Format data for BigQuery"""
    def process(self, event):
        yield {
            'event_id': event['event_id'],
            'user_id': event['user_id'],
            'event_type': event['event_type'],
            'timestamp': event['timestamp'],
            'date': event['date'],
            'hour': event['hour'],
            'device_category': event['device_category'],
            'properties': json.dumps(event['properties'])
        }

def run_pipeline():
    """Run the ETL pipeline"""
    options = PipelineOptions()

    with beam.Pipeline(options=options) as p:
        # Read from source
        events = (p
            | 'Read from PubSub' >> beam.io.ReadFromPubSub(
                subscription='projects/booster/subscriptions/events'
            )
            | 'Extract' >> beam.ParDo(ExtractEvents())
        )

        # Transform
        transformed = (events
            | 'Transform' >> beam.ParDo(TransformEvent())
            | 'Filter Valid' >> beam.ParDo(FilterValidEvents())
        )

        # Branch 1: Write to BigQuery
        (transformed
            | 'Format for BQ' >> beam.ParDo(FormatForBigQuery())
            | 'Write to BigQuery' >> beam.io.WriteToBigQuery(
                'booster:analytics.events',
                write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND
            )
        )

        # Branch 2: Aggregate by user
        user_aggregates = (transformed
            | 'Key by User' >> beam.Map(lambda e: (e['user_id'], e))
            | 'Group by User' >> beam.GroupByKey()
            | 'Aggregate' >> beam.ParDo(AggregateByUser())
            | 'Write Aggregates' >> beam.io.WriteToText('user_aggregates.txt')
        )

        # Branch 3: Count by event type
        (transformed
            | 'Key by Type' >> beam.Map(lambda e: (e['event_type'], 1))
            | 'Count by Type' >> beam.CombinePerKey(sum)
            | 'Format Counts' >> beam.Map(lambda kv: f'{kv[0]}: {kv[1]}')
            | 'Write Counts' >> beam.io.WriteToText('event_counts.txt')
        )

if __name__ == '__main__':
    run_pipeline()
