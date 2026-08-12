const assert = require("node:assert");
const { test } = require("node:test");
const axios = require("axios");

const { createServer } = require("../server");

test("home page serves HTTP 200", async () => {
  const server = createServer(0);
  const address = await new Promise((resolve) => {
    server.on("listening", () => resolve(server.address()));
  });
  try {
    const res = await axios.get(`http://localhost:${address.port}/`);
    assert.strictEqual(res.status, 200);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("unknown route returns 404", async () => {
  const server = createServer(0);
  const address = await new Promise((resolve) => {
    server.on("listening", () => resolve(server.address()));
  });
  try {
    await assert.rejects(
      axios.get(`http://localhost:${address.port}/does-not-exist`),
    );
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});