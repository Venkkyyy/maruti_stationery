// tag_products.js
// Uses Firestore REST API with the OAuth2 access token from firebase-tools
// Run: node bin/tag_products.js

const os = require('os');
const path = require('path');
const fs = require('fs');
const https = require('https');

const PROJECT_ID = 'maruti-stationery-d7862';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ── Read firebase-tools stored access + refresh token ──────────────────────

const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const firebaseConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));

// Use the bhupendra account which owns maruti-stationery-d7862
const bhupendraAccount = firebaseConfig.additionalAccounts?.find(
  (a) => a.user?.email === 'bhupendra.jogi.mitwpu@gmail.com'
);
const tokens = bhupendraAccount?.tokens ?? firebaseConfig.tokens;

// Firebase CLI public OAuth2 client credentials
const CLIENT_ID     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// ── Helpers ─────────────────────────────────────────────────────────────────

function httpsRequest(url, options = {}, body = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function refreshAccessToken(refreshTkn) {
  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: refreshTkn,
    grant_type: 'refresh_token',
  }).toString();

  const res = await httpsRequest(
    'https://oauth2.googleapis.com/token',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    body,
  );

  if (res.status !== 200) {
    throw new Error(`Token refresh failed: ${res.status} ${res.body}`);
  }
  return JSON.parse(res.body).access_token;
}

// ── Tag keyword lists ────────────────────────────────────────────────────────

const SCHOOL_KEYWORDS = [
  'notebook', 'note book', 'school', 'pencil', 'eraser', 'sharpener',
  'geometry', 'compass', 'scale', 'ruler', 'crayon', 'colour pencil',
  'color pencil', 'sketch', 'drawing', 'water color', 'watercolor',
  'glue stick', 'gum', 'textbook', 'text book', 'exam pad', 'chart paper',
  'graph paper', 'index card', 'flash card', 'backpack', 'school bag',
  'lunch box', 'tiffin', 'colouring', 'coloring', 'craft',
  'highlighter', 'marker', 'geometry box',
];

const OFFICE_KEYWORDS = [
  'register', 'file', 'folder', 'binder',
  'ball pen', 'gel pen', 'ink', 'stamp', 'stapler', 'staple', 'punch',
  'paper clip', 'rubber band', 'tape', 'scissor', 'cutter', 'envelope',
  'letterhead', 'visiting card', 'business card', 'calculator',
  'organiser', 'organizer', 'tray', 'calendar', 'planner', 'diary',
  'sticky note', 'post-it', 'whiteboard', 'board marker',
  'a4 paper', 'legal pad', 'memo', 'invoice', 'receipt book',
  'account book', 'ledger', 'voucher', 'carbon copy', 'peon book',
  'attendance register',
];

function matchesAny(text, keywords) {
  const lower = text.toLowerCase();
  return keywords.some((k) => lower.includes(k.toLowerCase()));
}

function getStrField(fields, key) {
  return fields[key]?.stringValue ?? '';
}

function getArrField(fields, key) {
  const arr = fields[key]?.arrayValue?.values ?? [];
  return arr.map((v) => v.stringValue ?? '');
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('═══════════════════════════════════════════════');
  console.log('  Auto-Tagger: back_to_school & office_essentials');
  console.log('═══════════════════════════════════════════════\n');

  // Get a fresh access token
  let accessToken;
  try {
    accessToken = await refreshAccessToken(tokens.refresh_token);
    console.log('✓ OAuth2 access token obtained.\n');
  } catch (e) {
    console.error('Failed to get access token:', e.message);
    process.exit(1);
  }

  const authHeaders = {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  };

  // Fetch all products (paginated)
  const allDocs = [];
  let pageToken = null;

  do {
    const url = new URL(`${BASE_URL}/products`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const res = await httpsRequest(url.toString(), { headers: authHeaders });
    if (res.status !== 200) {
      console.error(`ERROR fetching products: ${res.status}\n${res.body}`);
      process.exit(1);
    }

    const parsed = JSON.parse(res.body);
    const docs = parsed.documents ?? [];
    allDocs.push(...docs);
    pageToken = parsed.nextPageToken ?? null;
    console.log(`Fetched ${docs.length} products (total: ${allDocs.length})`);
  } while (pageToken);

  console.log(`\nTotal products: ${allDocs.length}\n`);

  let schoolUpdated = 0;
  let officeUpdated = 0;
  let skipped = 0;

  for (const doc of allDocs) {
    const docName = doc.name; // full resource path
    const fields  = doc.fields ?? {};

    const isActive = fields.isActive?.booleanValue ?? true;
    if (!isActive) { skipped++; continue; }

    const name        = getStrField(fields, 'name');
    const description = getStrField(fields, 'description');
    const brand       = getStrField(fields, 'brand');
    const existingTags = getArrField(fields, 'tags');

    const searchText = `${name} ${description} ${brand}`;

    const isSchool = matchesAny(searchText, SCHOOL_KEYWORDS);
    const isOffice = matchesAny(searchText, OFFICE_KEYWORDS);

    if (!isSchool && !isOffice) { skipped++; continue; }

    const newTags = [...existingTags];
    const added = [];

    if (isSchool && !newTags.includes('back_to_school')) {
      newTags.push('back_to_school');
      added.push('back_to_school');
    }
    if (isOffice && !newTags.includes('office_essentials')) {
      newTags.push('office_essentials');
      added.push('office_essentials');
    }

    if (added.length === 0) { skipped++; continue; }

    // PATCH only the tags field
    const patchUrl = `https://firestore.googleapis.com/v1/${docName}?updateMask.fieldPaths=tags`;
    const payload = JSON.stringify({
      fields: {
        tags: {
          arrayValue: {
            values: newTags.map((t) => ({ stringValue: t })),
          },
        },
      },
    });

    const patchRes = await httpsRequest(
      patchUrl,
      { method: 'PATCH', headers: authHeaders },
      payload,
    );

    if (patchRes.status === 200) {
      console.log(`✅ [${name}]  +${added.join(', ')}`);
      if (isSchool) schoolUpdated++;
      if (isOffice) officeUpdated++;
    } else {
      console.log(`❌ Failed [${name}]: ${patchRes.status}`);
    }
  }

  console.log('\n═══════════════════════════════════════════════');
  console.log('  Done!');
  console.log(`  Tagged as back_to_school    : ${schoolUpdated} products`);
  console.log(`  Tagged as office_essentials : ${officeUpdated} products`);
  console.log(`  Skipped                     : ${skipped} products`);
  console.log('═══════════════════════════════════════════════');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
