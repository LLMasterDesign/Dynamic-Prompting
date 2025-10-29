#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ BASIC USAGE EXAMPLE ▂▂▂▂▂▂▂▂▂▂▂▂

require 'dynamic_prompt'

# Initialize with Redis
puts "▛▞ Initializing DynamicPrompt..."
dp = DynamicPrompt.new(redis_url: 'redis://localhost:6379/0')

# Create a simple prompt file
prompt_content = <<~PROMPT
  You are a helpful AI assistant.
  
  ## CORE RULES
  1. Be concise and direct
  2. Provide accurate information
  3. Ask clarifying questions when needed
  
  ## COMMUNICATION STYLE
  Tone: Professional and friendly
  Default: 3-4 sentences per response
PROMPT

# Save to file
File.write('/tmp/example_prompt.md', prompt_content)

# Load the prompt
puts "\n▛▞ Loading prompt from file..."
dp.load('/tmp/example_prompt.md', force: true)

# Get active prompt
puts "\n▛▞ Active prompt loaded:"
puts dp.get_active[0..200] + "..."

# Modify the prompt
puts "\n▛▞ Modifying prompt: 'change tone to sarcastic'"
dp.modify('change tone to sarcastic', user_id: 'demo_user')

# Show differences
puts "\n▛▞ Changes made:"
puts dp.diff

# View history
puts "\n▛▞ Modification history:"
puts dp.logger.format_history(5)

# Revert to original
puts "\n▛▞ Reverting to original..."
dp.revert

# Verify reversion
puts "\n▛▞ After revert, changes:"
puts dp.diff

puts "\n✓ Demo complete!"

###▙▖▙▖▞▞▙ END :: BasicUsage ▂▂▂▂▂▂▂▂▂▂▂▂

