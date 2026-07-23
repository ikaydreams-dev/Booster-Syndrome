import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import fs from 'fs';

export class CSVHandler {
  async importCSV<T>(filePath: string): Promise<T[]> {
    const fileContent = fs.readFileSync(filePath, 'utf-8');

    const records = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
    });

    return records as T[];
  }

  async exportCSV<T extends Record<string, any>>(
    data: T[],
    filePath: string,
    columns?: string[]
  ): Promise<void> {
    const output = stringify(data, {
      header: true,
      columns: columns,
    });

    fs.writeFileSync(filePath, output);
  }

  parseCSVString<T>(csvString: string): T[] {
    return parse(csvString, {
      columns: true,
      skip_empty_lines: true,
    }) as T[];
  }

  toCSVString<T extends Record<string, any>>(data: T[], columns?: string[]): string {
    return stringify(data, {
      header: true,
      columns: columns,
    });
  }

  async importLargeCSV<T>(
    filePath: string,
    batchSize: number,
    onBatch: (batch: T[]) => Promise<void>
  ): Promise<void> {
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    const lines = fileContent.split('\n');
    const headers = lines[0];

    let batch: T[] = [];

    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;

      const csvChunk = headers + '\n' + lines[i];
      const record = parse(csvChunk, { columns: true })[0] as T;

      batch.push(record);

      if (batch.length >= batchSize) {
        await onBatch(batch);
        batch = [];
      }
    }

    if (batch.length > 0) {
      await onBatch(batch);
    }
  }
}

export const csvHandler = new CSVHandler();
