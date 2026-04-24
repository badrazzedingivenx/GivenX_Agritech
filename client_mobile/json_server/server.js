const jsonServer = require('json-server');

const server = jsonServer.create();
const router = jsonServer.router('db.json');
const middlewares = jsonServer.defaults();

server.use(jsonServer.bodyParser);
server.use(middlewares);

/* =========================
   LOGS (optional debug)
========================= */
server.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url}`);
  next();
});

/* =========================
   LOGIN (simple auth for Flutter)
========================= */
server.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  const users = router.db.get('users').value();

  const user = users.find(
    u => u.email === email && u.password === password
  );

  if (!user) {
    return res.status(401).json({
      success: false,
      message: "Invalid email or password",
      data: null
    });
  }

  return res.json({
    success: true,
    message: "Login successful",
    data: {
      token: "fake-token-" + user.id,
      user
    }
  });
});

/* =========================
   WRAP ALL JSON RESPONSES
========================= */
router.render = (req, res) => {
  res.json({
    success: true,
    message: "OK",
    data: res.locals.data
  });
};

/* =========================
   EXPLICIT DELETE ROUTES
   (prevent router.render conflict on DELETE)
========================= */
function explicitDelete(collection) {
  return (req, res) => {
    const id = Number(req.params.id);
    const col = router.db.get(collection);
    const item = col.find({ id }).value();
    if (!item) {
      return res.status(404).json({ success: false, message: `${collection} not found`, data: null });
    }
    col.remove({ id }).write();
    res.json({ success: true, message: 'Deleted', data: {} });
  };
}

server.delete('/api/products/:id',        explicitDelete('products'));
server.delete('/api/orders/:id',          explicitDelete('orders'));
server.delete('/api/shipments/:id',       explicitDelete('shipments'));
server.delete('/api/messages/:id',        explicitDelete('messages'));
server.delete('/api/users/:id',           explicitDelete('users'));
server.delete('/api/financeRequests/:id', explicitDelete('financeRequests'));

/* =========================
   USE API PREFIX
========================= */
server.use('/api', router);

/* =========================
   START SERVER
========================= */
const BASE_PORT = Number(process.env.PORT) || 3000;
const MAX_PORT_RETRIES = 10;

function startServer(port, retriesLeft = MAX_PORT_RETRIES) {
  const instance = server.listen(port, () => {
    console.log(`JSON Server running on http://localhost:${port}/api`);
  });

  instance.on('error', (err) => {
    if (err.code === 'EADDRINUSE' && retriesLeft > 0) {
      const nextPort = port + 1;
      console.warn(`Port ${port} is in use, retrying on ${nextPort}...`);
      startServer(nextPort, retriesLeft - 1);
      return;
    }

    console.error('Failed to start JSON server:', err.message);
    process.exit(1);
  });
}

startServer(BASE_PORT);