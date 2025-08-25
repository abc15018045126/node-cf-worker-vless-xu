export default {
  async fetch(request, env, ctx) {
    let url = new URL(request.url);
    url.hostname = '你的目标域名.com';
    //url.protocol = 'http:'; 如果你目标是 HTTP 源站
    let newRequest = new Request(url.toString(), request);
    return fetch(newRequest);
  }
}