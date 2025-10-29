#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ MCP TEST CLIENT ▂▂▂▂▂▂▂▂▂▂▂▂
# Test the MCP server locally

require 'json'
require 'open3'

def send_mcp_request(method, params = {})
  """Send request to MCP server and get response"""
  
  request = {
    method: method,
    params: params
  }
  
  puts "\n▛▞ REQUEST: #{method}"
  puts "   Params: #{params.inspect}"
  
  # Start server and send request
  Open3.popen3('ruby', File.join(__dir__, 'prompt_server.rb')) do |stdin, stdout, stderr, thread|
    # Send request
    stdin.puts(request.to_json)
    stdin.close
    
    # Read response
    response = stdout.gets
    
    if response
      result = JSON.parse(response)
      puts "▛▞ RESPONSE:"
      puts JSON.pretty_generate(result)
      result
    else
      puts "⚠️  No response received"
      nil
    end
  end
end

# Test sequence
puts "###▙▖▙▖▞▞▙ DYNAMIC PROMPT MCP TEST ▂▂▂▂▂▂▂▂▂▂▂▂"

# 1. Health check
send_mcp_request('health_check')

# 2. Create test prompt
test_prompt = <<~PROMPT
  You are a helpful assistant.
  
  ## RULES
  1. Be concise
  2. Be accurate
  
  Tone: Professional
PROMPT

File.write('/tmp/test_prompt.md', test_prompt)

# 3. Load prompt
send_mcp_request('load_prompt', { source: '/tmp/test_prompt.md', force: true })

# 4. Get active prompt
send_mcp_request('get_active_prompt')

# 5. Modify prompt
send_mcp_request('modify_prompt', { 
  instruction: 'change tone to sarcastic',
  user_id: 'test_user'
})

# 6. Show diff
send_mcp_request('show_diff')

# 7. Get history
send_mcp_request('get_history', { limit: 5 })

# 8. Get metadata
send_mcp_request('get_metadata')

puts "\n###▙▖▙▖▞▞▙ TEST COMPLETE ▂▂▂▂▂▂▂▂▂▂▂▂"

###▙▖▙▖▞▞▙ END :: MCPTest ▂▂▂▂▂▂▂▂▂▂▂▂

