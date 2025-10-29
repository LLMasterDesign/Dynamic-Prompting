#!/usr/bin/env ruby
# frozen_string_literal: true

###▙▖▙▖▞▞▙ MODIFIER ENGINE ▂▂▂▂▂▂▂▂▂▂▂▂
# Applies natural language modifications to prompts
# Pattern matching for common transformation requests

class DynamicPrompt
  class Modifier
    def apply(prompt, instruction)
      #       Apply modification to prompt based on natural language instruction
      
      Supported patterns:
        - "change tone to X"
        - "add rule: X"
        - "remove rule about X"
        - "default X sentences"
        - "set temperature to X"
        - "make more/less verbose"
      #       instruction_lower = instruction.downcase.strip
      modified = prompt.dup
      
      # Pattern: "change tone to X"
      if instruction_lower =~ /(?:change|set|make)\s+tone\s+(?:to\s+)?(.+)/
        modified = change_tone(modified, $1)
      end
      
      # Pattern: "add rule: X"
      if instruction_lower =~ /add\s+rule:?\s*(.+)/
        modified = add_rule(modified, $1)
      end
      
      # Pattern: "remove rule about X"
      if instruction_lower =~ /remove\s+rule\s+(?:about\s+)?(.+)/
        modified = remove_rule(modified, $1)
      end
      
      # Pattern: "default X sentences"
      if instruction_lower =~ /default\s+(\d+)\s+sentence/
        modified = change_sentence_default(modified, $1.to_i)
      end
      
      # Pattern: "make more verbose" or "make less verbose"
      if instruction_lower =~ /make\s+(more|less)\s+verbose/
        direction = $1
        modified = change_verbosity(modified, direction)
      end
      
      # Pattern: "be more/less X" (adjective)
      if instruction_lower =~ /be\s+(more|less)\s+(\w+)/
        intensity = $1
        trait = $2
        modified = adjust_trait(modified, trait, intensity)
      end
      
      modified
    end
    
    private
    
    def change_tone(prompt, new_tone)Change tone in prompt#       # Look for existing tone specification
      if prompt =~ /Tone:\s*.+$/i
        prompt.gsub(/Tone:\s*.+$/i, "Tone: #{new_tone.strip.capitalize}")
      elsif prompt =~ /(Communication Style|Response Style)/i
        # Add tone under style section
        prompt.gsub(/($1.+?\n)/i, "\\1Tone: #{new_tone.strip.capitalize}\n")
      else
        # Append tone specification
        prompt + "\n\nTone: #{new_tone.strip.capitalize}\n"
      end
    end
    
    def add_rule(prompt, rule_text)Add new rule to CORE RULES or RULES section#       # Find rules section
      if prompt =~ /(CORE RULES|RULES|GUIDELINES).*?\n(.*?)((?:\n\n|\z|###|▛))/mi
        section_header = $1
        rules_content = $2
        after_section = $3
        
        # Count existing rules
        rule_numbers = rules_content.scan(/^\s*(\d+)\./).flatten.map(&:to_i)
        next_number = rule_numbers.empty? ? 1 : rule_numbers.max + 1
        
        # Insert new rule
        new_rule = "#{next_number}. #{rule_text.strip}\n"
        updated_rules = rules_content + new_rule
        
        prompt.sub(/(#{section_header}.*?\n)(.*?)(#{Regexp.escape(after_section)})/mi, "\\1#{updated_rules}\\3")
      else
        # No rules section found, create one
        prompt + "\n\n## RULES\n1. #{rule_text.strip}\n"
      end
    end
    
    def remove_rule(prompt, topic)Remove rule matching topic#       # Find and remove matching rule line(s)
      prompt.gsub(/^\s*\d+\.\s+.*?#{Regexp.escape(topic)}.*?\n/i, '')
    end
    
    def change_sentence_default(prompt, num_sentences)Change default sentence count#       if prompt =~ /DEFAULT\s+\d+\s+SENTENCE/i
        prompt.gsub(/DEFAULT\s+\d+\s+SENTENCE/i, "DEFAULT #{num_sentences} SENTENCE")
      else
        prompt + "\n\nDEFAULT #{num_sentences} SENTENCES\n"
      end
    end
    
    def change_verbosity(prompt, direction)Increase or decrease verbosity#       if direction == "more"
        # Increase default sentences
        if prompt =~ /DEFAULT\s+(\d+)\s+SENTENCE/i
          current = $1.to_i
          prompt.gsub(/DEFAULT\s+\d+\s+SENTENCE/i, "DEFAULT #{current + 2} SENTENCES")
        else
          prompt + "\n\nNote: Provide more detailed explanations.\n"
        end
      else
        # Decrease verbosity
        if prompt =~ /DEFAULT\s+(\d+)\s+SENTENCE/i
          current = $1.to_i
          new_count = [current - 2, 1].max
          prompt.gsub(/DEFAULT\s+\d+\s+SENTENCE/i, "DEFAULT #{new_count} SENTENCE#{new_count > 1 ? 'S' : ''}")
        else
          prompt + "\n\nNote: Keep responses brief and concise.\n"
        end
      end
    end
    
    def adjust_trait(prompt, trait, intensity)Adjust personality trait (more/less)#       modifier = intensity == "more" ? "more" : "less"
      note = "\n\nNote: Be #{modifier} #{trait}.\n"
      
      # Check if similar note already exists
      if prompt =~ /Note: Be (more|less) #{trait}/i
        prompt.gsub(/Note: Be (more|less) #{trait}\.?\n/i, note)
      else
        prompt + note
      end
    end
  end
end

###▙▖▙▖▞▞▙ END :: Modifier ▂▂▂▂▂▂▂▂▂▂▂▂

