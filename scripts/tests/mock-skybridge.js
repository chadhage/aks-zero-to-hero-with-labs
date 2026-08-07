const net = require("node:net");

const server = net.createServer((socket) => {
  socket.setEncoding("utf8");
  socket.write("SKYBRIDGE READY\n");
  let pending = "";
  socket.on("data", (chunk) => {
    pending += chunk;
    const lines = pending.split("\n");
    pending = lines.pop();
    for (const line of lines) {
      if (line.startsWith("MSG ")) socket.write(`ACK id=test parser=mock ${line.slice(4)}\n`);
      else socket.write("ERR expected MSG\n");
    }
  });
});

server.listen(Number(process.argv[2]), "127.0.0.1", () => {
  console.log(server.address().port);
});