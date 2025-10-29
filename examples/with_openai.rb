#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ OPENAI :: INTEGRATION EXAMPLE ▂▂▂▂▂▂▂▂▂▂▂▂
# Shows how to use DynamicPrompt with OpenAI API

require 'dynamic_prompt'
require 'httparty'

class AIChat
  def initialize(api_key:, redis_url: 'redis://localhost:6379/0')
    @api_key = api_key
    @prompt_manager = DynamicPrompt.new(redis_url: redis_url)
    @conversation_history = []
  end
  
  def load_prompt(source)
    """Load system prompt from file/URL"""
    @prompt_manager.load(source, force: true)
    puts "✓ Prompt loaded"
  end
  
  def modify_personality(instruction)
    """Modify AI personality on-the-fly"""
    @prompt_manager.modify(instruction, user_id: 'user')
    puts "✓ Personality modified: #{instruction}"
  end
  
  def chat(user_message)
    """Send message to OpenAI with dynamic prompt"""
    
    # Get current system prompt from Redis
    system_prompt = @prompt_manager.get_active
    
    # Build messages
    messages = [
      { role: 'system', content: system_prompt },
      *@conversation_history,
      { role: 'user', content: user_message }
    ]
    
    # Call OpenAI API
    response = HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'gpt-4',
        messages: messages,
        temperature: 0.7
      }.to_json
    )
    
    if response.success?
      ai_reply = response.parsed_response['choices'][0]['message']['content']
      
      # Store in conversation (but NOT the system prompt - it's in Redis!)
      @conversation_history << { role: 'user', content: user_message }
      @conversation_history << { role: 'assistant', content: ai_reply }
      
      # Keep history manageable
      @conversation_history = @conversation_history.last(10) if @conversation_history.length > 10
      
      ai_reply
    else
      "Error: #{response.code} - #{response.message}"
    end
  end
  
  def show_prompt_changes
    """Display modifications to original prompt"""
    @prompt_manager.diff
  end
end

# Example usage
if __FILE__ == $0
  # Check for API key
  api_key = ENV['OPENAI_API_KEY']
  
  unless api_key
    puts "⚠️  Set OPENAI_API_KEY environment variable"
    exit 1
  end
  
  # Initialize
  chat = AIChat.new(api_key: api_key)
  
  # Create and load prompt
  prompt = <<~PROMPT
    You are a helpful coding assistant.
    
    ## RULES
    1. Provide concise code examples
    2. Explain your reasoning
    3. Use modern best practices
    
    Tone: Professional
    Default: 2-3 sentences
  PROMPT
  
  File.write('/tmp/coding_assistant.md', prompt)
  chat.load_prompt('/tmp/coding_assistant.md')
  
  # Chat
  puts "\n▛▞ User: How do I reverse a string in Ruby?"
  response = chat.chat("How do I reverse a string in Ruby?")
  puts "▛▞ AI: #{response}"
  
  # Modify personality mid-conversation
  puts "\n▛▞ Modifying personality to be more playful..."
  chat.modify_personality('change tone to playful and use analogies')
  
  # Continue chatting with new personality
  puts "\n▛▞ User: What about reversing an array?"
  response = chat.chat("What about reversing an array?")
  puts "▛▞ AI: #{response}"
  
  # Show what changed
  puts "\n▛▞ Prompt modifications:"
  puts chat.show_prompt_changes
end

###▙▖▙▖▞▞▙ END :: OpenAIIntegration ▂▂▂▂▂▂▂▂▂▂▂▂

