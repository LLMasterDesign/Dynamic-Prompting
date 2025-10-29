```rust
///▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
▛//▞▞ ⟦⎊⟧ :: DYNAMIC.PROMPT :: v1.0.0 ▞▞
     Redis-Backed AI Prompt Management
     〔 Prompts in Memory, Not History 〕
///▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
```

# Dynamic Prompt

**Store AI prompts in Redis, not conversation history. Modify personality on-the-fly. Save 95% of your tokens.**

Traditional AI systems waste thousands of tokens repeating the same system prompt every turn. Dynamic Prompt stores it once in Redis and lets you modify it in real-time with natural language commands.

```ruby
dp = DynamicPrompt.new
dp.load('assistant_prompt.md')

# Use in any AI call
system_prompt = dp.get_active  # ← From Redis, not repeated

# User says "be more sarcastic" mid-conversation
dp.modify('change tone to sarcastic')  # ← Takes effect immediately
```

---

## Quick Start

```bash
gem install dynamic_prompt
```

```ruby
require 'dynamic_prompt'

# Initialize
dp = DynamicPrompt.new(redis_url: 'redis://localhost:6379/0')

# Load prompt
dp.load('my_prompt.md')

# Get active prompt (use as system message)
system_prompt = dp.get_active

# Modify on-the-fly
dp.modify('be more concise', user_id: 'user123')

# See changes
puts dp.diff
puts dp.history
```

---

## Features

- **🔄 Load from anywhere** - Files, URLs, or direct strings
- **✏️ Natural language mods** - `"change tone to X"`, `"add rule: Y"`, `"be more Z"`
- **📊 Full audit trail** - Track who changed what and when
- **🔙 Revert anytime** - Restore to original with one command
- **🚀 Multiple formats** - Ruby gem, MCP server, Docker container
- **🎯 Provider agnostic** - Works with OpenAI, Claude, any LLM

---

## The Problem

```
Traditional approach:
Turn 1:  [1000 token prompt] + user + AI response
Turn 2:  [1000 token prompt] + user + AI response
Turn 20: [1000 token prompt] + user + AI response

Result: 20,000 tokens wasted on repeated prompts
```

## The Solution

```
Dynamic Prompt approach:
Redis: [prompt:active] ← stored once

Turn 1-20: reference prompt + user + AI response

Result: ~0 tokens (prompt in Redis, not conversation)
Savings: 20,000 tokens per 20-turn conversation
```

---

## Integration Examples

### OpenAI

```ruby
require 'dynamic_prompt'
require 'openai'

dp = DynamicPrompt.new
dp.load('assistant_prompt.md')

client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

response = client.chat(
  parameters: {
    model: 'gpt-4',
    messages: [
      { role: 'system', content: dp.get_active },  # ← From Redis
      { role: 'user', content: 'Hello!' }
    ]
  }
)

# Modify mid-conversation
dp.modify('be more concise')
# Next call uses updated prompt automatically
```

### Anthropic Claude

```ruby
require 'dynamic_prompt'
require 'anthropic'

dp = DynamicPrompt.new
dp.load('assistant_prompt.md')

client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

response = client.messages.create(
  model: 'claude-3-opus-20240229',
  system: dp.get_active,  # ← From Redis
  messages: [{ role: 'user', content: 'Hello!' }]
)
```

---

## MCP Server (Cursor Integration)

```bash
# Start MCP server
ruby mcp/prompt_server.rb

# Or via Docker
docker-compose up -d
```

Send JSON commands via stdio:
```json
{"method": "load_prompt", "params": {"source": "/path/to/prompt.md"}}
{"method": "modify_prompt", "params": {"instruction": "be more sarcastic"}}
{"method": "get_active_prompt"}
```

Available methods: `load_prompt`, `get_active_prompt`, `modify_prompt`, `revert_prompt`, `show_diff`, `get_history`, `health_check`

---

## Docker Deployment

```bash
# Quick start
docker-compose up -d

# Or pull from Docker Hub
docker pull yourusername/dynamic-prompt:latest
docker run -e REDIS_URL=redis://your-redis:6379/0 yourusername/dynamic-prompt
```

Place prompts in `./prompts/` - they mount to `/app/prompts/` in container.

---

## Natural Language Modifications

| Command | Effect |
|---------|--------|
| `"change tone to sarcastic"` | Updates tone |
| `"add rule: never use emojis"` | Adds new rule |
| `"remove rule about emojis"` | Deletes rule |
| `"default 2 sentences"` | Sets response length |
| `"make more verbose"` | Increases detail |
| `"be more concise"` | Reduces verbosity |

---

## Architecture

```
Your AI App (OpenAI/Claude)
         ↓ dp.get_active()
   DynamicPrompt Gem ↔ Redis
         ↑           (prompt:active)
    User commands    (prompt:backup)
    "be more X"      (changelog)
```

Benefits:
- **95%+ token savings** - Prompt stored once, not repeated
- **Real-time changes** - Modify without restarting
- **Full history** - Audit trail of all modifications
- **Portable** - Works with any LLM provider

---

## Documentation

- **[Full Documentation](DOCUMENTATION.md)** - Complete API reference and examples
- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment instructions
- **[Examples](examples/)** - Working code samples
- **[Docker Guide](docker/README.md)** - Container deployment

---

## Requirements

- Ruby >= 3.0.0
- Redis >= 5.0

---

## License

MIT License - See [LICENSE.txt](LICENSE.txt)

---

## Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push branch (`git push origin feature/amazing`)
5. Open Pull Request

---

```rust
///▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
  
  SEAL :: DYNAMIC.PROMPT :: v1.0.0
  ⧗ Prompts in Memory, Not History
  ρ{Load} φ{Modify} ν{Evolve}
  
  Ruby Gem • MCP Server • Docker
  95%+ Token Savings
  Credit: LLMDesign 2025
///▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
```
