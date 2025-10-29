###▙▖▙▖▞▞▙ DOCKERFILE :: DYNAMIC PROMPT ▂▂▂▂▂▂▂▂▂▂▂▂

FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemspec and Gemfile first for better caching
COPY dynamic_prompt.gemspec Gemfile ./
COPY lib/dynamic_prompt/version.rb ./lib/dynamic_prompt/

# Install gems
RUN bundle install

# Copy application code
COPY . .

# Create output directory
RUN mkdir -p /app/output

# Set environment variables
ENV REDIS_URL=redis://redis:6379/0
ENV OUTPUT_PATH=/app/output

# Expose port for optional HTTP API
EXPOSE 3000

# Default command: run MCP server
CMD ["ruby", "mcp/prompt_server.rb"]

###▙▖▙▖▞▞▙ END :: Dockerfile ▂▂▂▂▂▂▂▂▂▂▂▂

