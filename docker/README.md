# Docker Deployment

## Quick Start

```bash
# Start Redis and MCP server
docker-compose up -d

# View logs
docker-compose logs -f prompt_server

# Stop services
docker-compose down
```

## Usage

### Interacting with MCP Server

```bash
# Send commands via stdin
echo '{"method":"health_check","params":{}}' | docker exec -i dynamic_prompt_server ruby mcp/prompt_server.rb

# Load a prompt
echo '{"method":"load_prompt","params":{"source":"/app/prompts/my_prompt.md"}}' | docker exec -i dynamic_prompt_server ruby mcp/prompt_server.rb
```

### Mounting Custom Prompts

Place your prompt files in `./prompts/` directory - they'll be available at `/app/prompts/` in the container.

### Persistent Storage

Redis data persists in the `redis_data` Docker volume.

## Environment Variables

- `REDIS_URL`: Redis connection string (default: `redis://redis:6379/0`)
- `OUTPUT_PATH`: Path for logs and output (default: `/app/output`)

## Building Locally

```bash
docker build -t dynamic-prompt:latest .
```

## Production Deployment

For production, consider:
1. Using Redis with authentication
2. Setting up proper networking/firewall rules
3. Mounting SSL certificates if exposing HTTP API
4. Using Docker secrets for sensitive config

