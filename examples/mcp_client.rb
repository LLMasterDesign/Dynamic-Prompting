#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ MCP :: CLIENT EXAMPLE ▂▂▂▂▂▂▂▂▂▂▂▂
# Shows how to interact with the MCP server programmatically

require 'json'
require 'open3'

class DynamicPromptMCPClient
  def initialize(server_command = 'ruby mcp/prompt_server.rb')
    @server_command = server_command
  end
  
  def send_request(method, params = {})
    """Send request to MCP server and get response"""
    
    request = {
      method: method,
      params: params
    }
    
    # Execute server and send request
    Open3.popen3(@server_command) do |stdin, stdout, stderr, thread|
      # Send JSON request
      stdin.puts(request.to_json)
      stdin.close
      
      # Read JSON response
      response_line = stdout.gets
      
      if response_line
        JSON.parse(response_line, symbolize_names: true)
      else
        { error: 'No response from server' }
      end
    end
  end
  
  def load_prompt(source, force: false)
    send_request('load_prompt', { source: source, force: force })
  end
  
  def get_active_prompt
    send_request('get_active_prompt')
  end
  
  def modify_prompt(instruction, user_id: 'client')
    send_request('modify_prompt', { instruction: instruction, user_id: user_id })
  end
  
  def revert_prompt
    send_request('revert_prompt')
  end
  
  def show_diff
    send_request('show_diff')
  end
  
  def get_history(limit: 10)
    send_request('get_history', { limit: limit })
  end
  
  def health_check
    send_request('health_check')
  end
end

# Example usage
if __FILE__ == $0
  puts "###▙▖▙▖▞▞▙ MCP CLIENT DEMO ▂▂▂▂▂▂▂▂▂▂▂▂\n"
  
  client = DynamicPromptMCPClient.new
  
  # Health check
  puts "▛▞ Health Check"
  result = client.health_check
  puts "   Status: #{result[:status]}"
  puts "   Version: #{result[:version]}"
  
  # Create test prompt
  prompt = <<~PROMPT
    You are an AI assistant.
    
    ## RULES
    1. Be helpful
    2. Be honest
    
    Tone: Friendly
  PROMPT
  
  File.write('/tmp/test_mcp_prompt.md', prompt)
  
  # Load prompt
  puts "\n▛▞ Loading Prompt"
  result = client.load_prompt('/tmp/test_mcp_prompt.md', force: true)
  puts "   Success: #{result[:success]}"
  puts "   Size: #{result[:loaded_size]} chars"
  
  # Get active
  puts "\n▛▞ Getting Active Prompt"
  result = client.get_active_prompt
  puts "   Loaded: #{result[:success]}"
  puts "   Preview: #{result[:prompt][0..80]}..."
  
  # Modify
  puts "\n▛▞ Modifying Prompt"
  result = client.modify_prompt('add rule: never use emojis', user_id: 'demo')
  puts "   Success: #{result[:success]}"
  
  # Show diff
  puts "\n▛▞ Showing Diff"
  result = client.show_diff
  puts result[:diff]
  
  # Get history
  puts "\n▛▞ History"
  result = client.get_history(limit: 5)
  puts result[:formatted]
  
  puts "\n###▙▖▙▖▞▞▙ DEMO COMPLETE ▂▂▂▂▂▂▂▂▂▂▂▂"
end

###▙▖▙▖▞▞▙ END :: MCPClient ▂▂▂▂▂▂▂▂▂▂▂▂

