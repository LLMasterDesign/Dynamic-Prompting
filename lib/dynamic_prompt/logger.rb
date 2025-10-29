#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ LOGGER :: AUDIT TRAIL ▂▂▂▂▂▂▂▂▂▂▂▂
# Tracks all prompt modifications with timestamps
# Maintains changelog in Redis

class DynamicPrompt
  class Logger
    CHANGELOG_KEY = "prompt:changelog"
    MAX_HISTORY = 100
    
    def initialize(redis)
      @redis = redis
    end
    
    def log_action(action, metadata = {})
      """Log general action (load, revert, etc)"""
      
      entry = {
        timestamp: Time.now.to_i,
        action: action,
        metadata: metadata
      }
      
      @redis.lpush(CHANGELOG_KEY, entry.to_json)
      @redis.ltrim(CHANGELOG_KEY, 0, MAX_HISTORY - 1)
    end
    
    def log_modification(user_id, instruction)
      """Log prompt modification"""
      
      entry = {
        timestamp: Time.now.to_i,
        action: 'modify',
        user_id: user_id,
        instruction: instruction
      }
      
      @redis.lpush(CHANGELOG_KEY, entry.to_json)
      @redis.ltrim(CHANGELOG_KEY, 0, MAX_HISTORY - 1)
    end
    
    def get_history(limit = 10)
      """Retrieve modification history"""
      
      entries = @redis.lrange(CHANGELOG_KEY, 0, limit - 1)
      
      entries.map do |entry_json|
        JSON.parse(entry_json, symbolize_names: true)
      end
    end
    
    def clear_all!
      """Clear entire changelog"""
      @redis.del(CHANGELOG_KEY)
    end
    
    def format_history(limit = 10)
      """Get formatted history for display"""
      
      history = get_history(limit)
      
      return "No history" if history.empty?
      
      history.map do |entry|
        time = Time.at(entry[:timestamp]).strftime('%Y-%m-%d %H:%M:%S')
        action = entry[:action]
        
        case action
        when 'modify'
          "#{time} | MODIFY | #{entry[:user_id]} | #{entry[:instruction]}"
        when 'load'
          source = entry[:metadata][:source] || 'unknown'
          "#{time} | LOAD | Source: #{source}"
        when 'revert'
          "#{time} | REVERT | Restored to original"
        else
          "#{time} | #{action.upcase}"
        end
      end.join("\n")
    end
  end
end

###▙▖▙▖▞▞▙ END :: Logger ▂▂▂▂▂▂▂▂▂▂▂▂

