import express from "express";
import { Server } from "colyseus";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { createServer } from "http";

const port = Number(process.env.PORT || 3000);
const app = express();
const server = createServer(app);

const gameServer = new Server({
  transport: new WebSocketTransport({
    server
  })
});

// Define rooms here
// gameServer.define("game_room", GameRoom);

server.listen(port, () => {
  console.log(`Backend live server running on port ${port}`);
});
