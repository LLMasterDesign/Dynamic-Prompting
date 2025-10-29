# frozen_string_literal: true

###▙▖▙▖▞▞▙ RAKEFILE :: DYNAMIC PROMPT ▂▂▂▂▂▂▂▂▂▂▂▂

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run MCP server"
task :mcp do
  exec "ruby mcp/prompt_server.rb"
end

desc "Run basic example"
task :example do
  exec "ruby examples/basic_usage.rb"
end

desc "Build and push Docker image"
task :docker_publish, [:version] do |t, args|
  version = args[:version] || "latest"
  image_name = "yourusername/dynamic-prompt"
  
  puts "Building Docker image..."
  system("docker build -t #{image_name}:#{version} .")
  
  puts "Tagging as latest..."
  system("docker tag #{image_name}:#{version} #{image_name}:latest")
  
  puts "Pushing to Docker Hub..."
  system("docker push #{image_name}:#{version}")
  system("docker push #{image_name}:latest")
  
  puts "✓ Published #{image_name}:#{version}"
end

###▙▖▙▖▞▞▙ END :: Rakefile ▂▂▂▂▂▂▂▂▂▂▂▂

