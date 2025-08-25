// --- Backend Logic ---

const cidrRanges = [
  '173.245.48.0/20', '103.21.244.0/22', '103.22.200.0/22', '103.31.4.0/22',
  '141.101.64.0/18', '108.162.192.0/18', '190.93.240.0/20', '188.114.96.0/20',
  '197.234.240.0/22', '198.41.128.0/17', '162.158.0.0/15', '104.16.0.0/13',
  '104.24.0.0/14', '172.64.0.0/13', '131.0.72.0/22'
];

function ipToLong(ip) {
  return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet, 10), 0) >>> 0;
}

function longToIp(long) {
  return [(long >>> 24) & 255, (long >>> 16) & 255, (long >>> 8) & 255, long & 255].join('.');
}

function getRandomIpFromCidr(cidr) {
  const [ip, maskStr] = cidr.split('/');
  const mask = parseInt(maskStr, 10);
  const network = ipToLong(ip) & (-1 << (32 - mask));
  const broadcast = network | (~(-1 << (32 - mask)));
  const start = network + 1;
  const end = broadcast - 1;
  if (start > end) return longToIp(network);
  const range = end - start + 1;
  const randomIpLong = Math.floor(Math.random() * range) + start;
  return longToIp(randomIpLong);
}

function generateVlessLink(uuid, domain, ip) {
  const sni = domain.replace(/^(https?:\/\/)/, '');
  const path = '/proxyip=ProxyIP.US.CMLiussss.net';
  return `vless://${uuid}@${ip}:443?encryption=none&security=tls&sni=${sni}&fp=randomized&allowInsecure=1&type=ws&host=${sni}&path=${encodeURIComponent(path)}#${sni}-${ip}`;
}

async function handleApiRequest(request) {
  const { searchParams } = new URL(request.url);
  const domain = searchParams.get('domain');
  const uuid = searchParams.get('uuid');
  const countParam = searchParams.get('count');

  if (!domain || !uuid) {
      return new Response('Missing required parameters: "domain" and "uuid" are required.', {
          status: 400,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      });
  }

  const count = Math.min(Math.max(1, parseInt(countParam, 10) || 5), 50);
  const generatedLinks = [];
  for (let i = 0; i < count; i++) {
      if (i === 0) {
          // First link uses domain directly
          const link = generateVlessLink(uuid, domain, domain);
          generatedLinks.push(link);
      } else {
          const randomCidr = cidrRanges[Math.floor(Math.random() * cidrRanges.length)];
          const randomIp = getRandomIpFromCidr(randomCidr);
          const link = generateVlessLink(uuid, domain, randomIp);
          generatedLinks.push(link);
      }
  }

  const responseBody = generatedLinks.join('\n');
  return new Response(responseBody, {
      headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Access-Control-Allow-Origin': '*'
      },
  });
}

// --- Frontend ---

const html = `
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>VLESS Link Generator</title>
<style>
  body { font-family: Arial, sans-serif; background: #fff; margin: 0; padding: 20px; color: #000; }
  .container { max-width: 600px; margin: 0 auto; background: #fff; padding: 20px; border-radius: 12px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
  h1 { text-align: center; color: #000; }
  label { display: block; margin: 12px 0 6px; font-weight: bold; }
  input { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 8px; }
  button { width: 100%; margin-top: 15px; padding: 12px; background: #007BFF; color: #fff; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; }
  button:hover { background: #0056b3; }
  .output-container { margin-top: 20px; position: relative; }
  .button-row { display: flex; gap: 10px; margin-bottom: 10px; }
  .button-row button { flex: 1; }
  .copy-btn { padding: 12px; background: #007BFF; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; }
  .copy-btn:hover { background: #0056b3; }
  pre { background: #f8f9fa; color: #000; padding: 15px; border-radius: 8px; white-space: pre-wrap; word-wrap: break-word; border: 1px solid #ddd; }
</style>
</head>
<body>
<div class="container">
  <h1>VLESS Link Generator</h1>
  <label for="domain">Domain</label>
  <input type="text" id="domain" placeholder="your.domain.com">

  <label for="uuid">UUID</label>
  <input type="text" id="uuid" placeholder="UUID">

  <label for="count">Count</label>
  <input type="number" id="count" value="5" min="1" max="50">

  <div class="button-row">
    <button id="generate-btn">Generate Links</button>
    <button class="copy-btn" id="copy-btn">Copy</button>
  </div>

  <div class="output-container">
    <pre id="output"></pre>
  </div>
</div>

<script>
  document.getElementById('generate-btn').addEventListener('click', async () => {
    const domain = document.getElementById('domain').value.trim();
    const uuid = document.getElementById('uuid').value.trim();
    const count = document.getElementById('count').value.trim();
    if (!domain || !uuid) {
      alert('Please enter both domain and UUID');
      return;
    }
    try {
      const url = '/generate?domain=' + encodeURIComponent(domain) + '&uuid=' + encodeURIComponent(uuid) + '&count=' + count;
      const response = await fetch(url);
      const text = await response.text();
      document.getElementById('output').textContent = text;
    } catch (err) {
      alert('Error: ' + err.message);
    }
  });

  document.getElementById('copy-btn').addEventListener('click', () => {
    const output = document.getElementById('output').textContent;
    if (!output) {
      alert('No links to copy!');
      return;
    }
    navigator.clipboard.writeText(output).then(() => {
      alert('Copied to clipboard!');
    }).catch(err => {
      alert('Failed to copy: ' + err);
    });
  });
</script>
</body>
</html>`;

// --- Worker Entry ---

export default {
async fetch(request) {
  const url = new URL(request.url);
  if (url.pathname === '/generate') {
    return handleApiRequest(request);
  }
  if (url.pathname === '/') {
    return new Response(html, { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
  }
  return new Response('Not Found', { status: 404 });
}
};
