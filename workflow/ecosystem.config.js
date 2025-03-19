module.exports = {
  apps: [{
    name: "htmx-middleware",
    script: "app.js",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: "200M",
    env: {
      NODE_ENV: "production",
      MIDDLEWARE_PORT: 3000,
      POSTGREST_URL: "http://localhost:3001"
    }
  }]
}; 