#!/usr/bin/env ruby

require 'fileutils'
require 'securerandom'

def install_snippets
  puts 'Installing ResearchKit code snippets...'

  # Define paths
  script_dir = File.dirname(__FILE__)
  pod_root = File.expand_path('..', script_dir)
  snippets_source_dir = File.join(pod_root, 'Snippets')
  user_snippets_dir = File.expand_path('~/Library/Developer/Xcode/UserData/CodeSnippets/')

  # Create user snippets directory if it doesn't exist
  FileUtils.mkdir_p(user_snippets_dir)

  # Process each .codesnippet file in the Snippets directory (including subfolders)
  Dir.glob(File.join(snippets_source_dir, '**', '*.codesnippet')).each do |snippet_file|

    puts "Processing snippet file: #{snippet_file}"
    snippet_content = File.read(snippet_file)

    # Generate a new UUID for the snippet
    new_uuid = SecureRandom.uuid

    # Replace the existing UUID with the new one
    updated_content = snippet_content.gsub(/<key>IDECodeSnippetIdentifier<\/key>\s*<string>.*?<\/string>/, "<key>IDECodeSnippetIdentifier</key>\n\t<string>#{new_uuid}</string>")

    # Extract the title for logging
    title_match = snippet_content.match(/<key>IDECodeSnippetTitle<\/key>\s*<string>(.*?)<\/string>/)
    title = title_match ? title_match[1] : "Unknown"

    # Create a new filename with the new UUID
    new_filename = "#{new_uuid}.codesnippet"
    new_filepath = File.join(user_snippets_dir, new_filename)

    # Write the updated content to the user's snippets directory
    File.write(new_filepath, updated_content)

    puts "Installed snippet: #{title}"
  end

  puts 'ResearchKit code snippets installation complete!'
end

install_snippets
