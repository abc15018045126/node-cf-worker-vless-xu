import { connect } from 'cloudflare:sockets';

const proxyip = '';
const utf8Decoder = new TextDecoder("utf-8");

async function hp(rq, en) {
  try {
    let cp = en.proxyip || proxyip;
    const urlStr = rq.url;
    const pathIndex = urlStr.indexOf('/', 8);
    if (pathIndex > -1 && urlStr.substring(pathIndex).toLowerCase().startsWith('/proxyip=')) {
      const np = urlStr.substring(pathIndex + 9).trim();
      if (np) cp = np;
    }

    if (rq.headers.get('Upgrade')?.toLowerCase() !== 'websocket')
      return new Response('Worker is running. Expecting a WebSocket upgrade.', { status: 200 });

    const [c1, c2] = Object.values(new WebSocketPair());
    let rs = null, ic = 0;
    const cl = () => { if (ic) return; ic = 1; try { c2.close(); } catch {} try { rs?.close(); } catch {} };
    const wt = async (wr, da) => { const w = wr.getWriter(); await w.write(da); w.releaseLock(); };
    const ht = async (h, p, y) => {
      const cw = async (ad, p) => { const so = connect({ hostname: ad, port: p }); if (y?.length) await wt(so.writable, y); return so; };
      const pr = async (so, rf) => {
        rs = so;
        let hi = 0;
        await rs.readable.pipeTo(new WritableStream({ write: ck => { hi = 1; if (c2.readyState === WebSocket.OPEN) c2.send(ck); } })).catch(() => {});
        if (ic) return;
        if (!hi && rf) await rf(); else cl();
      };
      const rw = cp ? async () => { try { await pr(await cw(cp, p), null); } catch { cl(); } } : null;
      try { await pr(await cw(h, p), rw); } catch { if (rw) await rw(); else cl(); }
    };

    const om = async ev => {
      if (ic) return;
      try {
        // 避免重复 new Uint8Array
        let ms = ev.data;
        if (!(ms instanceof Uint8Array)) {
          ms = new Uint8Array(ms);
        }

        if (rs) { 
          await wt(rs.writable, ms); 
          return; 
        }

        if (ms.length < 19) throw 0;
        let of = 17;
        of += ms[of++] + 1;
        if (ms.length < of + 3) throw 0;
        if (ms[of++] !== 1) throw 0;

        const dv = new DataView(ms.buffer, ms.byteOffset, ms.byteLength);
        const po = dv.getUint16(of, false); of += 2;

        let ho;
        switch (ms[of++]) {
          case 1: // IPv4
            ho = `${ms[of]}.${ms[of+1]}.${ms[of+2]}.${ms[of+3]}`;
            of += 4;
            break;
          case 2: { // 域名
            const ln = ms[of++];
            ho = utf8Decoder.decode(ms.subarray(of, of + ln));
            of += ln;
            break;
          }
          case 3: { // IPv6
            let s = '[';
            for (let i = 0; i < 8; i++) {
              s += dv.getUint16(of + i*2, false).toString(16);
              if (i < 7) s += ':';
            }
            ho = s + ']';
            of += 16;
            break;
          }
          default: throw 0;
        }

        c2.send(new Uint8Array([ms[0],0]));
        await ht(ho, po, ms.subarray(of));
      } catch { 
        cl(); 
      }
    };

    const eh = rq.headers.get('sec-websocket-protocol');
    if (eh) {
      try { 
        await om({ data: Uint8Array.from(atob(eh.replace(/-/g,'+').replace(/_/g,'/')), c=>c.charCodeAt(0)).buffer }); 
      } catch { cl(); }
    }
    c2.accept();
    c2.addEventListener('close', cl);
    c2.addEventListener('error', cl);
    c2.addEventListener('message', om);
    return new Response(null, { status: 101, webSocket: c1 });
  } catch { 
    return new Response('Internal Server Error', { status: 500 }); 
  }
}

export default { fetch: hp };
