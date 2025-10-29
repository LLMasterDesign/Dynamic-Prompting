#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ STORAGE LAYER :: REDIS ▂▂▂▂▂▂▂▂▂▂▂▂
# Manages prompt persistence in Redis
# Keys: prompt:active, prompt:backup, prompt:changelog

class DynamicPrompt
  class Storage
    ACTIVE_KEY = "prompt:active"
    BACKUP_KEY = "prompt:backup"
    
    def initialize(redis)
      @redis = redis
    end
    
    def exists?Check if active prompt exists in Redis#       @redis.exists?(ACTIVE_KEY) > 0
    end
    
    def get_activeRetrieve active prompt#       @redis.get(ACTIVE_KEY)
    end
    
    def set_active(content)Store active prompt#       @redis.set(ACTIVE_KEY, content)
    end
    
    def get_backupRetrieve backup (original) prompt#       @redis.get(BACKUP_KEY)
    end
    
    def set_backup(content)Store backup (original) prompt#       @redis.set(BACKUP_KEY, content)
    end
    
    def clear_all!Delete all stored prompts#       @redis.del(ACTIVE_KEY, BACKUP_KEY)
    end
    
    def get_metadataGet storage metadata#       {
        active_exists: exists?,
        active_size: get_active&.length || 0,
        backup_exists: @redis.exists?(BACKUP_KEY) > 0,
        backup_size: get_backup&.length || 0
      }
    end
  end
end

###▙▖▙▖▞▞▙ END :: Storage ▂▂▂▂▂▂▂▂▂▂▂▂

