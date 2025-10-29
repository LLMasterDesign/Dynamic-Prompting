#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../lib/dynamic_prompt'

###▙▖▙▖▞▞▙ MCP SERVER :: DYNAMIC PROMPT ▂▂▂▂▂▂▂▂▂▂▂▂
# Model Context Protocol server for Cursor integration
# Provides prompt management via stdio protocol

class DynamicPromptMCPServer
  def initialize
    redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    @prompt_manager = DynamicPrompt.new(redis_url: redis_url)
    @output_path = ENV['OUTPUT_PATH'] || File.join(__dir__, '..', 'output')
    FileUtils.mkdir_p(@output_path) rescue nil
  end
  
  def start
    """Start MCP server listening on STDIN"""
    
    STDERR.puts "✓ DynamicPrompt MCP Server started"
    STDERR.puts "  Redis: #{ENV['REDIS_URL'] || 'localhost:6379'}"
    STDERR.puts "  Output: #{@output_path}"
    
    STDIN.each_line do |line|
      line = line.strip
      next if line.empty?
      
      begin
        request = JSON.parse(line)
        method = request['method']
        params = request['params'] || {}
        
        response = handle_request(method, params)
        
        STDOUT.puts(response.to_json)
        STDOUT.flush
      rescue JSON::ParserError => e
        error = { error: "Invalid JSON: #{e.message}" }
        STDOUT.puts(error.to_json)
        STDOUT.flush
      rescue => e
        error = { error: "Server error: #{e.message}", backtrace: e.backtrace.take(5) }
        STDOUT.puts(error.to_json)
        STDOUT.flush
      end
    end
  end
  
  def handle_request(method, params)
    """Route MCP request to appropriate handler"""
    
    result = case method
    when 'load_prompt'
      load_prompt(params['source'], params['force'])
      
    when 'get_active_prompt'
      get_active_prompt
      
    when 'modify_prompt'
      modify_prompt(params['instruction'], params['user_id'])
      
    when 'revert_prompt'
      revert_prompt
      
    when 'show_diff'
      show_diff
      
    when 'get_history'
      get_history(params['limit'])
      
    when 'clear_prompts'
      clear_prompts
      
    when 'get_metadata'
      get_metadata
      
    when 'health_check'
      health_check
      
    else
      { error: "Unknown method: #{method}" }
    end
    
    log_request(method, params, result)
    result
  end
  
  private
  
  def load_prompt(source, force = false)
    """Load prompt from file, URL, or string"""
    
    return { error: "No source provided" } unless source
    
    begin
      content = @prompt_manager.load(source, force: force || false)
      
      {
        success: true,
        source: source,
        loaded_size: content.length,
        message: "Prompt loaded successfully"
      }
    rescue => e
      { error: "Failed to load prompt: #{e.message}" }
    end
  end
  
  def get_active_prompt
    """Retrieve current active prompt"""
    
    prompt = @prompt_manager.get_active
    
    if prompt
      {
        success: true,
        prompt: prompt,
        size: prompt.length
      }
    else
      {
        success: false,
        message: "No active prompt loaded"
      }
    end
  end
  
  def modify_prompt(instruction, user_id = 'mcp_client')
    """Modify active prompt"""
    
    return { error: "No instruction provided" } unless instruction
    
    begin
      updated = @prompt_manager.modify(instruction, user_id: user_id || 'mcp_client')
      
      if updated
        {
          success: true,
          instruction: instruction,
          new_size: updated.length,
          message: "Prompt modified successfully"
        }
      else
        {
          success: false,
          error: "No active prompt to modify"
        }
      end
    rescue => e
      { error: "Failed to modify prompt: #{e.message}" }
    end
  end
  
  def revert_prompt
    """Revert prompt to original"""
    
    begin
      backup = @prompt_manager.revert
      
      if backup
        {
          success: true,
          message: "Prompt reverted to original",
          size: backup.length
        }
      else
        {
          success: false,
          error: "No backup available"
        }
      end
    rescue => e
      { error: "Failed to revert: #{e.message}" }
    end
  end
  
  def show_diff
    """Show differences between active and original"""
    
    begin
      diff = @prompt_manager.diff
      
      {
        success: true,
        diff: diff,
        has_changes: diff != "No modifications (active = original)"
      }
    rescue => e
      { error: "Failed to generate diff: #{e.message}" }
    end
  end
  
  def get_history(limit = 10)
    """Get modification history"""
    
    begin
      history = @prompt_manager.history(limit: limit || 10)
      formatted = @prompt_manager.logger.format_history(limit || 10)
      
      {
        success: true,
        history: history,
        formatted: formatted,
        count: history.length
      }
    rescue => e
      { error: "Failed to get history: #{e.message}" }
    end
  end
  
  def clear_prompts
    """Clear all prompts and history"""
    
    begin
      @prompt_manager.clear!
      
      {
        success: true,
        message: "All prompts and history cleared"
      }
    rescue => e
      { error: "Failed to clear: #{e.message}" }
    end
  end
  
  def get_metadata
    """Get system metadata"""
    
    begin
      storage_meta = @prompt_manager.storage.get_metadata
      
      {
        success: true,
        metadata: storage_meta,
        version: DynamicPrompt::VERSION
      }
    rescue => e
      { error: "Failed to get metadata: #{e.message}" }
    end
  end
  
  def health_check
    """Health check for monitoring"""
    
    {
      success: true,
      status: "healthy",
      version: DynamicPrompt::VERSION,
      redis_connected: @prompt_manager.storage.exists?.is_a?(TrueClass) || @prompt_manager.storage.exists?.is_a?(FalseClass),
      timestamp: Time.now.to_i
    }
  end
  
  def log_request(method, params, result)
    """Log MCP request for debugging"""
    
    log_entry = {
      timestamp: Time.now.to_i,
      method: method,
      params: params,
      success: !result.key?(:error)
    }
    
    log_file = File.join(@output_path, 'mcp_server.log')
    File.open(log_file, 'a', encoding: 'UTF-8') do |f|
      f.puts log_entry.to_json
    end
  rescue => e
    STDERR.puts "Warning: Failed to log request: #{e.message}"
  end
end

###▙▖▙▖▞▞▙ STDIO PROTOCOL HANDLER ▂▂▂▂▂▂▂▂▂▂▂▂

if __FILE__ == $0
  server = DynamicPromptMCPServer.new
  server.start
end

###▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂
# SEAL :: DYNAMIC.PROMPT.MCP :: ρ{Load} φ{Modify} ν{Evolve}
# ⧗ :: AI Prompt Management via Model Context Protocol
# Real-time modifications, audit trail, context window optimization
# :: ∎
###▙▖▙▖▞▞▙▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂

