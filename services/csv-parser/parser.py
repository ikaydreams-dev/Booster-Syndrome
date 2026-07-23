import csv
import io

class CSVParser:
    def parse(self, csv_data):
        """Parse CSV data"""
        if isinstance(csv_data, bytes):
            csv_data = csv_data.decode('utf-8')

        reader = csv.DictReader(io.StringIO(csv_data))
        return list(reader)

    def parse_with_headers(self, csv_data, headers):
        """Parse CSV with custom headers"""
        if isinstance(csv_data, bytes):
            csv_data = csv_data.decode('utf-8')

        reader = csv.reader(io.StringIO(csv_data))
        next(reader)  # Skip header row

        results = []
        for row in reader:
            results.append(dict(zip(headers, row)))

        return results

    def validate_csv(self, csv_data, required_columns):
        """Validate CSV has required columns"""
        if isinstance(csv_data, bytes):
            csv_data = csv_data.decode('utf-8')

        reader = csv.DictReader(io.StringIO(csv_data))

        fieldnames = reader.fieldnames or []

        missing = set(required_columns) - set(fieldnames)

        return {
            'valid': len(missing) == 0,
            'missing_columns': list(missing),
            'found_columns': fieldnames
        }
