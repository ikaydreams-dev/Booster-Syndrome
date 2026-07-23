import csv
import io

class CSVExporter:
    def export_users(self, users):
        """Export users to CSV"""
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=['id', 'email', 'username', 'created_at'])

        writer.writeheader()
        for user in users:
            writer.writerow({
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'created_at': user['created_at']
            })

        return output.getvalue()

    def export_events(self, events):
        """Export analytics events to CSV"""
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=['id', 'event_type', 'user_id', 'timestamp'])

        writer.writeheader()
        for event in events:
            writer.writerow({
                'id': event['id'],
                'event_type': event['event_type'],
                'user_id': event.get('user_id', ''),
                'timestamp': event['timestamp']
            })

        return output.getvalue()
