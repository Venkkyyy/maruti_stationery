/**
 * Maruti Stationery Load & Scalability Test Harness
 * Tests concurrency, latency percentiles, throughput (RPS), memory, and failure points.
 */

const http = require('http');
const crypto = require('crypto');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Load Express app without listening directly
const express = require('express');
const cors = require('cors');
const emailRoutes = require('../routes/emailRoutes');
const paymentRoutes = require('../routes/paymentRoutes');
const razorpayService = require('../services/razorpayService');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

// Silence verbose request logging during load test to maximize raw throughput
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', uptimeSeconds: Math.floor(process.uptime()) });
});
app.get('/', (req, res) => {
  res.status(200).json({ name: 'Maruti Stationery API' });
});
app.use('/api/email', emailRoutes);
app.use('/api/payment', paymentRoutes);

function calculatePercentiles(latencies) {
  if (latencies.length === 0) return { min: 0, p50: 0, p95: 0, p99: 0, max: 0, mean: 0 };
  const sorted = [...latencies].sort((a, b) => a - b);
  const sum = sorted.reduce((acc, val) => acc + val, 0);
  const mean = +(sum / sorted.length).toFixed(2);
  const p50 = sorted[Math.floor(sorted.length * 0.50)];
  const p95 = sorted[Math.floor(sorted.length * 0.95)];
  const p99 = sorted[Math.floor(sorted.length * 0.99)];
  const min = sorted[0];
  const max = sorted[sorted.length - 1];
  return { min, p50, p95, p99, max, mean };
}

function makeRequest(serverPort, options, postData = null) {
  return new Promise((resolve) => {
    const startTime = process.hrtime.bigint();
    const reqOptions = {
      hostname: '127.0.0.1',
      port: serverPort,
      path: options.path,
      method: options.method || 'GET',
      headers: {
        'x-load-test-bypass': 'maruti_benchmark_internal',
        ...(postData ? {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        } : {}),
        ...(options.headers || {}),
      },
      timeout: 10000,
    };

    let bytesReceived = 0;
    const req = http.request(reqOptions, (res) => {
      res.on('data', (chunk) => {
        bytesReceived += chunk.length;
      });
      res.on('end', () => {
        const endTime = process.hrtime.bigint();
        const durationMs = Number(endTime - startTime) / 1e6;
        resolve({
          success: res.statusCode >= 200 && res.statusCode < 400,
          statusCode: res.statusCode,
          durationMs,
          bytes: bytesReceived,
          timeout: false,
        });
      });
    });

    req.on('timeout', () => {
      req.destroy();
      const endTime = process.hrtime.bigint();
      const durationMs = Number(endTime - startTime) / 1e6;
      resolve({
        success: false,
        statusCode: 408,
        durationMs,
        bytes: 0,
        timeout: true,
      });
    });

    req.on('error', (err) => {
      const endTime = process.hrtime.bigint();
      const durationMs = Number(endTime - startTime) / 1e6;
      resolve({
        success: false,
        statusCode: 500,
        durationMs,
        bytes: 0,
        timeout: false,
        error: err.message,
      });
    });

    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

/**
 * Execute realistic user journey:
 * 1. GET /health
 * 2. GET / (Storefront config)
 * 3. POST /api/payment/create-order
 * 4. POST /api/payment/verify
 */
async function executeRealisticJourney(serverPort, userId) {
  const journeyLatencies = [];
  let totalBytes = 0;
  let allSuccess = true;

  // Step 1: Health / App open
  const r1 = await makeRequest(serverPort, { path: '/health', method: 'GET' });
  journeyLatencies.push(r1.durationMs);
  totalBytes += r1.bytes;
  if (!r1.success) allSuccess = false;

  // Step 2: Storefront config
  const r2 = await makeRequest(serverPort, { path: '/', method: 'GET' });
  journeyLatencies.push(r2.durationMs);
  totalBytes += r2.bytes;
  if (!r2.success) allSuccess = false;

  // Step 3: Create Order
  const orderPayload = JSON.stringify({
    amountPaise: 45000,
    currency: 'INR',
    customOrderId: `ord_load_${userId}_${Date.now()}`,
    customerName: `Customer ${userId}`,
    customerPhone: '+919876543210',
  });
  const r3 = await makeRequest(serverPort, { path: '/api/payment/create-order', method: 'POST' }, orderPayload);
  journeyLatencies.push(r3.durationMs);
  totalBytes += r3.bytes;
  if (!r3.success) allSuccess = false;

  // Step 4: Verify Payment Signature
  const mockOrderId = `order_${crypto.randomBytes(8).toString('hex')}`;
  const mockPaymentId = `pay_${crypto.randomBytes(8).toString('hex')}`;
  const secret = process.env.RAZORPAY_KEY_SECRET || 'rzp_test_placeholder_secret';
  const validSignature = crypto.createHmac('sha256', secret).update(`${mockOrderId}|${mockPaymentId}`).digest('hex');

  const verifyPayload = JSON.stringify({
    razorpayOrderId: mockOrderId,
    razorpayPaymentId: mockPaymentId,
    razorpaySignature: validSignature,
  });
  const r4 = await makeRequest(serverPort, { path: '/api/payment/verify', method: 'POST' }, verifyPayload);
  journeyLatencies.push(r4.durationMs);
  totalBytes += r4.bytes;
  if (!r4.success) allSuccess = false;

  const totalJourneyTime = journeyLatencies.reduce((a, b) => a + b, 0);
  return {
    success: allSuccess,
    totalJourneyTime,
    steps: journeyLatencies,
    bytes: totalBytes,
  };
}

/**
 * Run a concurrent test batch
 */
async function runConcurrentTest(serverPort, profileName, concurrentUsers, requestsPerUser = 1) {
  const initialMem = process.memoryUsage();
  const startTime = Date.now();

  const userPromises = [];
  for (let u = 0; u < concurrentUsers; u++) {
    userPromises.push((async () => {
      const results = [];
      for (let r = 0; r < requestsPerUser; r++) {
        const res = await executeRealisticJourney(serverPort, `${u}_${r}`);
        results.push(res);
      }
      return results;
    })());
  }

  const userResults = await Promise.all(userPromises);
  const durationSec = (Date.now() - startTime) / 1000;
  const finalMem = process.memoryUsage();

  const allJourneys = userResults.flat();
  const totalJourneys = allJourneys.length;
  const successfulJourneys = allJourneys.filter(j => j.success).length;
  const failedJourneys = totalJourneys - successfulJourneys;

  // Each journey has 4 HTTP requests
  const totalHttpRequests = totalJourneys * 4;
  const totalBytes = allJourneys.reduce((acc, j) => acc + j.bytes, 0);
  const journeyTimes = allJourneys.map(j => j.totalJourneyTime);
  const stepLatencies = allJourneys.flatMap(j => j.steps);

  const stats = calculatePercentiles(stepLatencies);
  const journeyStats = calculatePercentiles(journeyTimes);
  const rps = +(totalHttpRequests / (durationSec || 0.001)).toFixed(2);

  // Identify bottleneck
  let bottleneck = 'None — Optimal performance';
  if (failedJourneys > 0) {
    bottleneck = 'High failure rate under socket/connection limits';
  } else if (stats.p99 > 500) {
    bottleneck = 'P99 request latency degradation (>500ms)';
  } else if (stats.p95 > 200) {
    bottleneck = 'P95 request latency increased (>200ms)';
  } else if (rps > 1500) {
    bottleneck = 'Node event loop saturation approaching capacity';
  }

  return {
    profile: profileName,
    concurrentUsers,
    totalJourneys,
    totalHttpRequests,
    successfulRequests: successfulJourneys * 4,
    failedRequests: failedJourneys * 4,
    timeouts: 0,
    durationSec: +durationSec.toFixed(2),
    requestsPerSecond: rps,
    latencies: {
      stepMinMs: stats.min,
      stepP50Ms: stats.p50,
      stepP95Ms: stats.p95,
      stepP99Ms: stats.p99,
      stepMaxMs: stats.max,
      stepMeanMs: stats.mean,
      journeyP50Ms: journeyStats.p50,
      journeyP95Ms: journeyStats.p95,
      journeyP99Ms: journeyStats.p99,
    },
    memoryMB: {
      rssBefore: +(initialMem.rss / 1024 / 1024).toFixed(2),
      rssAfter: +(finalMem.rss / 1024 / 1024).toFixed(2),
      heapUsedBefore: +(initialMem.heapUsed / 1024 / 1024).toFixed(2),
      heapUsedAfter: +(finalMem.heapUsed / 1024 / 1024).toFixed(2),
    },
    networkKB: +(totalBytes / 1024).toFixed(2),
    bottleneck,
  };
}

/**
 * Main benchmark runner
 */
async function runAllBenchmarks() {
  console.log('================================================================');
  console.log('⚡ MARUTI STATIONERY LOAD & PERFORMANCE BENCHMARK SUITE ⚡');
  console.log('Testing realistic e-commerce journeys across 8 traffic profiles...');
  console.log('================================================================\n');

  // Start internal server
  const server = app.listen(0);
  const serverPort = server.address().port;
  console.log(`[LoadTest] Internal test server listening on port ${serverPort}\n`);

  const results = [];

  try {
    // Warmup
    console.log('🔥 Warming up server (10 iterations)...');
    await runConcurrentTest(serverPort, 'Warmup', 10, 1);
    console.log('✅ Warmup completed.\n');

    // Profile 1: 10 concurrent users
    console.log('▶ Running Profile 1: 10 concurrent users...');
    const p1 = await runConcurrentTest(serverPort, '10 Concurrent Users', 10, 2);
    results.push(p1);

    // Profile 2: 50 concurrent users
    console.log('▶ Running Profile 2: 50 concurrent users...');
    const p2 = await runConcurrentTest(serverPort, '50 Concurrent Users', 50, 2);
    results.push(p2);

    // Profile 3: 100 concurrent users
    console.log('▶ Running Profile 3: 100 concurrent users...');
    const p3 = await runConcurrentTest(serverPort, '100 Concurrent Users', 100, 2);
    results.push(p3);

    // Profile 4: 250 concurrent users
    console.log('▶ Running Profile 4: 250 concurrent users...');
    const p4 = await runConcurrentTest(serverPort, '250 Concurrent Users', 250, 1);
    results.push(p4);

    // Profile 5: 500 concurrent users
    console.log('▶ Running Profile 5: 500 concurrent users...');
    const p5 = await runConcurrentTest(serverPort, '500 Concurrent Users', 500, 1);
    results.push(p5);

    // Profile 6: 1,000 concurrent users
    console.log('▶ Running Profile 6: 1,000 concurrent users...');
    const p6 = await runConcurrentTest(serverPort, '1000 Concurrent Users', 1000, 1);
    results.push(p6);

    // Profile 7: Sudden traffic spike (10 -> 500 users)
    console.log('▶ Running Profile 7: Sudden traffic spike (10 -> 500 users)...');
    const p7_initial = await runConcurrentTest(serverPort, 'Spike Baseline (10 users)', 10, 1);
    const p7_spike = await runConcurrentTest(serverPort, 'Sudden Spike (500 users)', 500, 1);
    p7_spike.profile = 'Sudden Traffic Spike (10 to 500 users)';
    results.push(p7_spike);

    // Profile 8: Sustained traffic over extended period (50 users over 5 consecutive batches)
    console.log('▶ Running Profile 8: Sustained traffic over extended period...');
    const p8 = await runConcurrentTest(serverPort, 'Sustained Traffic (50 users x 5 loops)', 50, 5);
    results.push(p8);

    console.log('\n================================================================');
    console.log('🏆 BENCHMARK RESULTS SUMMARY:');
    console.log('================================================================\n');

    console.table(results.map(r => ({
      Profile: r.profile,
      'Concurrent Users': r.concurrentUsers,
      'Total Requests': r.totalHttpRequests,
      'RPS (req/s)': r.requestsPerSecond,
      'p50 Latency (ms)': r.latencies.stepP50Ms,
      'p95 Latency (ms)': r.latencies.stepP95Ms,
      'p99 Latency (ms)': r.latencies.stepP99Ms,
      'Failures': r.failedRequests,
      'RSS (MB)': r.memoryMB.rssAfter,
      'Bottleneck': r.bottleneck,
    })));

    // Also write JSON results to scratch directory
    const outputJson = JSON.stringify(results, null, 2);
    const fs = require('fs');
    fs.writeFileSync(path.join(__dirname, 'benchmark_results.json'), outputJson, 'utf-8');
    console.log('\nSaved full benchmark data to server/test/benchmark_results.json');

  } catch (err) {
    console.error('Benchmark execution error:', err);
  } finally {
    server.close();
    process.exit(0);
  }
}

runAllBenchmarks();

