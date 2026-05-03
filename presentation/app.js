function orderedMeta(meta = {}) {
  return Object.entries(meta).sort((a, b) => a[0].localeCompare(b[0]))
}

function renderNode(nodeId, nodes) {
  const node = nodes[nodeId]
  if (!node) {
    const li = document.createElement("li")
    li.textContent = `[missing] ${nodeId}`
    return li
  }
  const li = document.createElement("li")
  const label = document.createElement("span")
  label.className = "node"
  label.textContent = `${node.label} `
  const sid = document.createElement("small")
  sid.textContent = `(${node.id})`
  label.appendChild(sid)
  li.appendChild(label)

  if (node.children && node.children.length > 0) {
    const ul = document.createElement("ul")
    for (const childId of node.children) {
      ul.appendChild(renderNode(childId, nodes))
    }
    li.appendChild(ul)
  }
  return li
}

async function bootWasm() {
  try {
    const bytes = await fetch("./kernel.wasm")
    if (!bytes.ok) return { loaded: false, reason: `no wasm (${bytes.status})` }
    const mod = await WebAssembly.instantiateStreaming(bytes)
    return { loaded: true, exports: Object.keys(mod.instance.exports) }
  } catch (err) {
    return { loaded: false, reason: err instanceof Error ? err.message : String(err) }
  }
}

async function main() {
  const [treeResp, wasm] = await Promise.all([fetch("./tree.json"), bootWasm()])
  const meta = document.getElementById("meta")
  const treeEl = document.getElementById("tree")
  if (!treeResp.ok) {
    meta.textContent = `could not load tree.json (${treeResp.status})`
    return
  }
  const payload = await treeResp.json()
  const details = {
    schema: payload.kind,
    root: payload.root,
    node_count: Object.keys(payload.nodes || {}).length,
    wasm_loaded: wasm.loaded,
    wasm_info: wasm.loaded ? (wasm.exports || []).join(",") : wasm.reason,
  }
  meta.textContent = orderedMeta(details).map(([k, v]) => `${k}: ${v}`).join("\n")
  treeEl.innerHTML = ""
  treeEl.appendChild(renderNode(payload.root, payload.nodes || {}))
}

main()
