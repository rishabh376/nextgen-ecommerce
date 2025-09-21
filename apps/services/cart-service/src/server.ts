import express from "express";
import helmet from "helmet";
import cors from "cors";
import { Registry, collectDefaultMetrics, Histogram } from "prom-client";
import pino from "pino";
import pinoHttp from "pino-http";
import { CosmosClient } from "@azure/cosmos";
import Redis from "ioredis";

const port = process.env.PORT || 8080;
const cosmosConn = process.env.COSMOS_CONN_STR!;
const redisConn = process.env.REDIS_CONN_STR!;
const dbName = process.env.COSMOS_DB || "ecom";
const cartsContainer = process.env.CARTS_CONTAINER || "carts";

if (!cosmosConn || !redisConn) {
  console.error("Missing COSMOS_CONN_STR or REDIS_CONN_STR");
  process.exit(1);
}

const logger = pino();
const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(pinoHttp({ logger }));

const registry = new Registry();
collectDefaultMetrics({ register: registry });
const httpLatency = new Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP latency",
  labelNames: ["method", "route", "code"],
  buckets: [0.05, 0.1, 0.2, 0.5, 1, 2],
});
registry.registerMetric(httpLatency);

const cosmos = new CosmosClient(cosmosConn);
const db = cosmos.database(dbName);
const carts = db.container(cartsContainer);

const redis = new Redis(redisConn, { enableAutoPipelining: true });

app.get("/healthz", (_req, res) => res.status(200).send("ok"));
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", registry.contentType);
  res.end(await registry.metrics());
});

// GET cart
app.get("/cart/:userId", async (req, res) => {
  const start = Date.now();
  const { userId } = req.params;
  try {
    const cached = await redis.get(`cart:${userId}`);
    if (cached) return res.json(JSON.parse(cached));

    const { resource } = await carts.item(userId, userId).read<any>();
    const data = resource || { id: userId, userId, items: [] };
    await redis.setex(`cart:${userId}`, 30, JSON.stringify(data));
    res.json(data);
  } catch (err) {
    req.log.error({ err }, "get_cart_error");
    res.status(500).json({ error: "failed to get cart" });
  } finally {
    httpLatency.labels({ method: "GET", route: "/cart/:userId", code: res.statusCode.toString() })
      .observe((Date.now() - start) / 1000);
  }
});

// Add/update item
app.post("/cart/:userId/items", async (req, res) => {
  const start = Date.now();
  const { userId } = req.params;
  const { productId, qty } = req.body;
  if (!productId || qty == null) return res.status(400).json({ error: "productId and qty required" });

  try {
    const { resource } = await carts.items.query({
      query: "SELECT * FROM c WHERE c.id = @id",
      parameters: [{ name: "@id", value: userId }]
    }).fetchNext();

    const cart = resource?.[0] || { id: userId, userId, items: [] };
    const idx = cart.items.findIndex((i: any) => i.productId === productId);
    if (idx >= 0) cart.items[idx].qty = qty;
    else cart.items.push({ productId, qty });

    const { resource: up } = await carts.items.upsert(cart);
    await redis.del(`cart:${userId}`);
    res.json(up);
  } catch (err) {
    req.log.error({ err }, "update_cart_error");
    res.status(500).json({ error: "failed to update cart" });
  } finally {
    httpLatency.labels({ method: "POST", route: "/cart/:userId/items", code: res.statusCode.toString() })
      .observe((Date.now() - start) / 1000);
  }
});

// Remove item
app.delete("/cart/:userId/items/:productId", async (req, res) => {
  const start = Date.now();
  const { userId, productId } = req.params;
  try {
    const { resource } = await carts.item(userId, userId).read<any>();
    const cart = resource || { id: userId, userId, items: [] };
    cart.items = cart.items.filter((i: any) => i.productId !== productId);
    const { resource: up } = await carts.items.upsert(cart);
    await redis.del(`cart:${userId}`);
    res.json(up);
  } catch (err) {
    req.log.error({ err }, "remove_item_error");
    res.status(500).json({ error: "failed to remove item" });
  } finally {
    httpLatency.labels({ method: "DELETE", route: "/cart/:userId/items/:productId", code: res.statusCode.toString() })
      .observe((Date.now() - start) / 1000);
  }
});

app.listen(port, () => logger.info(`cart-service listening on ${port}`));