#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ DYNAMIC PROMPT :: SYSTEM ▂▂▂▂▂▂▂▂▂▂▂▂
# Redis-backed prompt management for AI agents
# Reduces context window usage by storing evolving prompts in memory
# Allows real-time modifications without conversation history bloat

require 'redis'
require 'json'
require 'uri'
require 'net/http'

require_relative 'dynamic_prompt/version'
require_relative 'dynamic_prompt/storage'
require_relative 'dynamic_prompt/modifier'
require_relative 'dynamic_prompt/logger'

class DynamicPrompt
  attr_reader :storage, :modifier, :logger
  
  def initialize(redis: nil, redis_url: nil)
    """
    Initialize Dynamic Prompt Manager
    
    Args:
      redis: Existing Redis connection (optional)
      redis_url: Redis connection string (optional, defaults to localhost)
    """
    
    @redis = redis || Redis.new(url: redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379/0')
    @storage = DynamicPrompt::Storage.new(@redis)
    @modifier = DynamicPrompt::Modifier.new
    @logger = DynamicPrompt::Logger.new(@redis)
    
    puts "✓ DynamicPrompt initialized"
  end
  
  def load(source, force: false)
    """
    Load prompt from file, URL, or direct string
    
    Args:
      source: File path, URL, or prompt string
      force: Overwrite existing prompt (default: false)
    
    Returns:
      Loaded prompt content
    """
    
    # Check if active prompt exists
    if @storage.exists? && !force
      puts "⚠️  Active prompt already exists. Use force: true to overwrite."
      return @storage.get_active
    end
    
    # Determine source type and load
    prompt_content = if source.start_with?('http://', 'https://')
      load_from_url(source)
    elsif File.exist?(source)
      load_from_file(source)
    else
      # Treat as direct string
      source
    end
    
    # Store in Redis
    @storage.set_active(prompt_content)
    @storage.set_backup(prompt_content)
    @logger.log_action('load', source: source)
    
    puts "✓ Prompt loaded (#{prompt_content.length} chars)"
    prompt_content
  end
  
  def get_active
    """Retrieve current active prompt from Redis"""
    @storage.get_active
  end
  
  def modify(instruction, user_id: 'system')
    """
    Modify active prompt based on natural language instruction
    
    Examples:
      - "change tone to sarcastic"
      - "add rule: no emojis"
      - "default 2 sentences"
      - "remove rule about encouragement"
    
    Args:
      instruction: Natural language modification command
      user_id: User making the change (for audit trail)
    
    Returns:
      Updated prompt content
    """
    
    current_prompt = @storage.get_active
    
    unless current_prompt
      puts "⚠️  No active prompt. Load one first with .load()"
      return nil
    end
    
    # Apply modification
    updated_prompt = @modifier.apply(current_prompt, instruction)
    
    # Store updated version
    @storage.set_active(updated_prompt)
    @logger.log_modification(user_id, instruction)
    
    puts "✓ Prompt modified: #{instruction}"
    updated_prompt
  end
  
  def revert
    """Restore prompt to original (canonical) version"""
    
    backup = @storage.get_backup
    
    unless backup
      puts "⚠️  No backup found"
      return nil
    end
    
    @storage.set_active(backup)
    @logger.log_action('revert')
    
    puts "✓ Prompt reverted to original"
    backup
  end
  
  def diff
    """Show changes between active and original prompt"""
    
    original = @storage.get_backup
    active = @storage.get_active
    
    return "No active prompt loaded" unless active
    return "No modifications (active = original)" if original == active
    
    # Simple line-by-line diff
    original_lines = original.lines
    active_lines = active.lines
    
    changes = []
    
    # Added/modified lines
    active_lines.each_with_index do |line, idx|
      if idx >= original_lines.length
        changes << "+ #{line.strip}"
      elsif original_lines[idx] != line
        changes << "~ #{line.strip}"
      end
    end
    
    # Removed lines
    if original_lines.length > active_lines.length
      (active_lines.length...original_lines.length).each do |idx|
        changes << "- #{original_lines[idx].strip}"
      end
    end
    
    changes.empty? ? "No differences" : changes.join("\n")
  end
  
  def history(limit: 10)
    """Get modification history (audit trail)"""
    @logger.get_history(limit)
  end
  
  def clear!
    """Clear all stored prompts and history (dangerous!)"""
    @storage.clear_all!
    @logger.clear_all!
    puts "✓ All prompts and history cleared"
  end
  
  private
  
  def load_from_file(path)
    """Load prompt from file system"""
    File.read(path, encoding: 'UTF-8')
  end
  
  def load_from_url(url)
    """Load prompt from HTTP(S) URL"""
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to load from URL: #{response.code} #{response.message}"
    end
    
    response.body
  end
end

###▙▖▙▖▞▞▙ END :: DynamicPrompt ▂▂▂▂▂▂▂▂▂▂▂▂

