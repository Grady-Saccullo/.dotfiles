#!/usr/bin/env node
// The automations daemon. Rules (from home-assistant-js-websocket's own
// issue tracker):
//  - never call getAuth() in Node; use a long-lived token
//  - the library has no keepalive: ping every 30 s, force reconnect on timeout
//  - subscriptions made while HA is not RUNNING silently never fire: after
//    every "ready", wait for RUNNING, then resync every machine from getStates
//  - machines derive state from entity truth, never from memory; every
//    service call is idempotent (turn_on, never toggle)
import {
  createConnection,
  createLongLivedTokenAuth,
  getStates,
  getConfig,
  callService,
  subscribeEvents,
  ERR_INVALID_AUTH,
  type Connection,
  type HassEntity,
} from "home-assistant-js-websocket";
import http from "node:http";
import { machines, type Action } from "./machines.js";

const url = process.env.HASS_URL;
const token = process.env.HASS_TOKEN;
if (!url || !token) {
  console.error("<2>HASS_URL and HASS_TOKEN are required");
  process.exit(1);
}

const auth = createLongLivedTokenAuth(url, token);
const conn: Connection = await createConnection({ auth, setupRetry: -1 });
let ready = false;
let lastEvent = 0;

async function waitRunning(): Promise<void> {
  for (;;) {
    const cfg = await getConfig(conn);
    if (cfg.state === "RUNNING") return;
    await new Promise((r) => setTimeout(r, 2000));
  }
}

async function resync(): Promise<void> {
  await waitRunning();
  const states = await getStates(conn);
  const byId = new Map<string, HassEntity>(states.map((s) => [s.entity_id, s]));
  for (const m of machines) m.resync(byId);
  ready = true;
  console.log("<6>resynced from " + states.length + " entities");
}

function run(a: Action): void {
  callService(conn, a.domain, a.service, a.data, a.target).catch((e) =>
    console.error("<3>service call failed: " + a.domain + "." + a.service + " " + String(e)),
  );
}

conn.addEventListener("ready", () => {
  resync().catch((e) => console.error("<3>resync failed: " + String(e)));
});
conn.addEventListener("disconnected", () => {
  ready = false;
  console.warn("<4>disconnected");
});
conn.addEventListener("reconnect-error", (_c, err) => {
  if (err === ERR_INVALID_AUTH) {
    console.error("<2>invalid token");
    process.exit(1);
  }
});

subscribeEvents(
  conn,
  (ev: any) => {
    lastEvent = Date.now();
    if (!ready) return;
    for (const m of machines) for (const a of m.handle(ev)) run(a);
  },
  "state_changed",
);

// keepalive the library lacks
setInterval(async () => {
  const t = setTimeout(() => conn.reconnect(true), 10_000);
  try {
    await conn.ping();
  } catch {
    conn.reconnect(true);
  } finally {
    clearTimeout(t);
  }
}, 30_000);

// health endpoint for Gatus
http
  .createServer((_req, res) => {
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ status: conn.connected && ready ? "UP" : "DOWN", lastEvent }));
  })
  .listen(Number(process.env.HEALTH_PORT ?? 9111), "127.0.0.1");

await resync();
