# Deployment Guide
```rust
###▙▖▙▖▞▞▙ DYNAMIC PROMPT :: DEPLOYMENT ▂▂▂▂▂▂▂▂▂▂▂▂

Complete guide for deploying Dynamic Prompt System to production.
```
## Pre-Deployment Checklist

- [ ] Redis server available (local or cloud)
- [ ] Ruby 3.0+ installed
- [ ] Docker installed (for containerized deployment)
- [ ] API keys set (if using OpenAI/Claude)
- [ ] Prompt files prepared

## Deployment Options

### Option 1: Ruby Gem (Simplest)

```bash
# Install gem
gem install dynamic_prompt

# Or add to Gemfile
echo 'gem "dynamic_prompt"' >> Gemfile
bundle install
```

**Use Case**: Integrate into existing Ruby application

**Pros**: Lightweight, direct integration
**Cons**: Requires Ruby environment

---

### Option 2: MCP Server (Cursor Integration)

```bash
# Clone repo
git clone https://github.com/yourusername/dynamic_prompt
cd dynamic_prompt

# Install dependencies
bundle install

# Set Redis URL
export REDIS_URL=redis://localhost:6379/0

# Run MCP server
ruby mcp/prompt_server.rb

# Or use executable
chmod +x exe/dynamic-prompt-mcp
./exe/dynamic-prompt-mcp
```

**Use Case**: Use with Cursor IDE or other MCP clients

**Pros**: IDE integration, protocol standard
**Cons**: Requires running server

---

### Option 3: Docker (Production Ready)

```bash
# Build image
docker build -t dynamic-prompt:1.0.0 .

# Run with docker-compose
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f prompt_server
```

**Use Case**: Production deployment, scalable infrastructure

**Pros**: Isolated, reproducible, includes Redis
**Cons**: Requires Docker knowledge

---

### Option 4: Docker Hub (Pre-built)

```bash
# Pull from Docker Hub
docker pull yourusername/dynamic-prompt:latest

# Run with existing Redis
docker run -d \
  -e REDIS_URL=redis://your-redis:6379/0 \
  --name dynamic-prompt \
  yourusername/dynamic-prompt:latest
```

**Use Case**: Quick deployment without building

**Pros**: No build step, maintained image
**Cons**: Trust external image

## Publishing Steps

### 1. Publish Ruby Gem to RubyGems.org

```bash
# Update version in lib/dynamic_prompt/version.rb
# VERSION = "1.0.0"

# Build gem
gem build dynamic_prompt.gemspec

# Create RubyGems account (if needed)
# Visit: https://rubygems.org/sign_up

# Add credentials
curl -u yourusername https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
chmod 0600 ~/.gem/credentials

# Push to RubyGems
gem push dynamic_prompt-1.0.0.gem

# Verify
gem search dynamic_prompt -r
```

### 2. Publish Docker Image to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build with version tag
docker build -t yourusername/dynamic-prompt:1.0.0 .

# Tag as latest
docker tag yourusername/dynamic-prompt:1.0.0 yourusername/dynamic-prompt:latest

# Push both tags
docker push yourusername/dynamic-prompt:1.0.0
docker push yourusername/dynamic-prompt:latest

# Verify
docker search yourusername/dynamic-prompt
```

### 3. Create GitHub Release

```bash
# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Create release on GitHub
# Visit: https://github.com/yourusername/dynamic_prompt/releases/new
# - Tag: v1.0.0
# - Title: Dynamic Prompt v1.0.0
# - Description: See CHANGELOG.md
# - Attach: dynamic_prompt-1.0.0.gem
```

## Production Configuration

### Redis Setup

#### Option A: Local Redis

```bash
# Install Redis
# Ubuntu/Debian
sudo apt-get install redis-server

# macOS
brew install redis

# Start Redis
redis-server

# Test connection
redis-cli ping
```

#### Option B: Redis Cloud (Recommended for Production)

Services:
- [Redis Cloud](https://redis.com/cloud/) - Managed Redis
- [AWS ElastiCache](https://aws.amazon.com/elasticache/) - AWS managed
- [Heroku Redis](https://elements.heroku.com/addons/heroku-redis) - Heroku addon

```bash
# Set connection string
export REDIS_URL=redis://username:password@host:port/db
```

### Environment Variables

Create `.env` file:

```bash
# Redis
REDIS_URL=redis://localhost:6379/0

# Output (logs)
OUTPUT_PATH=./output

# Optional: AI API keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

### Security Considerations

1. **Redis Authentication**
   ```bash
   # Configure Redis with password
   echo "requirepass your_secure_password" >> /etc/redis/redis.conf
   
   # Update connection string
   REDIS_URL=redis://:your_secure_password@localhost:6379/0
   ```

2. **Network Security**
   - Use firewall to restrict Redis port (6379)
   - Use SSL/TLS for Redis connections in production
   - Don't expose Redis publicly

3. **Access Control**
   - Track user_id in modifications
   - Implement authentication in your application
   - Audit changelog regularly

### Monitoring

```bash
# Check Redis memory usage
redis-cli info memory

# Monitor Redis commands
redis-cli monitor

# Check stored prompts
redis-cli GET prompt:active

# View changelog
redis-cli LRANGE prompt:changelog 0 -1
```

### Backup & Recovery

```bash
# Backup Redis data
redis-cli SAVE
# Or use automated backups with redis.conf
# save 900 1
# save 300 10

# Export prompt to file
redis-cli GET prompt:active > backup_prompt.txt

# Restore prompt from file
cat backup_prompt.txt | redis-cli -x SET prompt:active
```

## Testing in Production

```bash
# Health check
curl -X POST http://your-server/health_check

# Or for MCP server
echo '{"method":"health_check"}' | nc localhost 3000

# Load test prompt
echo '{"method":"load_prompt","params":{"source":"/app/prompts/test.md"}}' | \
  docker exec -i dynamic_prompt_server ruby mcp/prompt_server.rb
```

## Troubleshooting

### Redis Connection Issues

```bash
# Test Redis connection
redis-cli -u $REDIS_URL ping

# Check Redis is running
ps aux | grep redis

# View Redis logs
tail -f /var/log/redis/redis-server.log
```

### MCP Server Issues

```bash
# Check server logs
docker-compose logs -f prompt_server

# Test manually
echo '{"method":"health_check"}' | ruby mcp/prompt_server.rb

# Verify JSON format
echo '{"method":"health_check"}' | jq .
```

### Docker Issues

```bash
# Rebuild without cache
docker-compose build --no-cache

# View container logs
docker logs dynamic_prompt_server

# Access container shell
docker exec -it dynamic_prompt_server /bin/bash
```

## Scaling Considerations

### Multiple Instances

Redis acts as shared state - multiple application instances can share one Redis:

```
App Instance 1 ──┐
App Instance 2 ──┼──► Redis (shared prompt storage)
App Instance 3 ──┘
```

### Performance

- Redis is fast (100k+ ops/sec)
- Prompt reads are cached
- Modifications are async-safe
- No bottleneck until very high scale

### High Availability

For production HA setup:

1. **Redis Replication**
   - Master-replica setup
   - Automatic failover with Sentinel

2. **Load Balancing**
   - Multiple MCP servers behind load balancer
   - Shared Redis backend

3. **Monitoring**
   - Redis monitoring (memory, connections)
   - Application metrics
   - Error tracking

## Cost Estimates

### Redis Hosting
- **Local**: Free
- **Redis Cloud Free**: 30MB free
- **Redis Cloud Essentials**: $5/month (250MB)
- **AWS ElastiCache**: ~$15/month (cache.t3.micro)

### Compute
- **Local**: Free
- **VPS**: $5-10/month (DigitalOcean, Linode)
- **Heroku**: $7/month (hobby dyno)
- **AWS ECS**: ~$10-20/month

**Total estimated cost**: $10-25/month for production setup

## Support & Maintenance

### Updates

```bash
# Update gem
gem update dynamic_prompt

# Update Docker image
docker pull yourusername/dynamic-prompt:latest
docker-compose up -d
```

### Monitoring Checklist

- [ ] Redis memory usage < 80%
- [ ] Prompt modifications logged
- [ ] No connection errors
- [ ] Backup schedule active
- [ ] SSL certificates valid (if applicable)

## Next Steps

1. Choose deployment option
2. Set up Redis (local or cloud)
3. Configure environment variables
4. Deploy application
5. Load initial prompts
6. Test modifications
7. Monitor and iterate

---

```rust
###▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
# SEAL :: DEPLOYMENT.GUIDE
# ⧗ :: From Development to Production
# Credit: LLMDesign 2025
###▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
```

