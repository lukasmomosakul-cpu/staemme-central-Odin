const http = require('node:http');
const os = require('node:os');

const PORT = Number(process.env.PORT || 8787);
const GATEWAY_NAME = process.env.GATEWAY_NAME || os.hostname();
const GATEWAY_TOKEN = process.env.GATEWAY_TOKEN || '';

function json(res, status, body) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store'
  });
  res.end(JSON.stringify(body));
}

function authorized(req) {
  if (!GATEWAY_TOKEN) return false;
  const value = req.headers.authorization || '';
  return value === `Bearer ${GATEWAY_TOKEN}`;
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    return json(res, 200, { ok: true, service: 'odin-egress', gateway: GATEWAY_NAME });
  }

  if (req.method === 'GET' && req.url === '/status') {
    if (!authorized(req)) return json(res, 401, { ok: false, error: 'unauthorized' });
    return json(res, 200, {
      ok: true,
      gateway: GATEWAY_NAME,
      status: 'online',
      checked_at: new Date().toISOString()
    });
  }

  return json(res, 404, { ok: false, error: 'not_found' });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`odin-egress listening on :${PORT}`);
});
