export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    let path = url.pathname
    if (path === "/") path = "/index.html"
    const key = path.replace(/^\//, "")
    const object = await env.ASSETS.get(key)
    if (!object) return new Response("not found", { status: 404 })
    const headers = new Headers()
    object.writeHttpMetadata(headers)
    headers.set("cache-control", "public, max-age=60")
    return new Response(object.body, { headers })
  }
}
