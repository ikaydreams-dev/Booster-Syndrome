const http = require('http');

const TARGET_URL = 'http://localhost:8000';
const REQUESTS_PER_SECOND = 100;
const DURATION_SECONDS = 60;

let successCount = 0;
let errorCount = 0;

function makeRequest() {
  const startTime = Date.now();

  http.get(`${TARGET_URL}/health`, (res) => {
    const duration = Date.now() - startTime;

    if (res.statusCode === 200) {
      successCount++;
    } else {
      errorCount++;
    }
  }).on('error', () => {
    errorCount++;
  });
}

console.log(`Starting load test: ${REQUESTS_PER_SECOND} req/s for ${DURATION_SECONDS}s`);

const interval = setInterval(() => {
  for (let i = 0; i < REQUESTS_PER_SECOND; i++) {
    makeRequest();
  }
}, 1000);

setTimeout(() => {
  clearInterval(interval);
  console.log('\nLoad test complete!');
  console.log(`Success: ${successCount}`);
  console.log(`Errors: ${errorCount}`);
  process.exit(0);
}, DURATION_SECONDS * 1000);
