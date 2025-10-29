# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "dynamic_prompt"
  spec.version       = "1.0.0"
  spec.authors       = ["Dynamic Prompt Contributors"]
  spec.email         = ["info@example.com"]

  spec.summary       = "Redis-backed dynamic prompt management system for AI agents"
  spec.description   = "Store, modify, and evolve AI system prompts in Redis instead of conversation history. Reduces context window usage and enables real-time personality modifications."
  spec.homepage      = "https://github.com/yourusername/dynamic_prompt"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourusername/dynamic_prompt"
  spec.metadata["changelog_uri"] = "https://github.com/yourusername/dynamic_prompt/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "mcp/**/*",
    "examples/**/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  
  spec.bindir        = "exe"
  spec.executables   = ["dynamic-prompt-mcp"]
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "redis", "~> 5.0"
  spec.add_dependency "httparty", "~> 0.21"
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "pry", "~> 0.14"
end

