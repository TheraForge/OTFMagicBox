#!/usr/bin/env ruby

require "cgi"
require "fileutils"
require "json"
require "open3"

DEFAULT_OUTPUT = "badges/coverage.svg"
DEFAULT_TARGET = "OTFMagicBox.app"
DEFAULT_LABEL = "coverage"

def usage
  <<~USAGE
    Usage:
      ruby Scripts/generate_coverage_badge.rb 82.4
      ruby Scripts/generate_coverage_badge.rb /tmp/OTFMagicBox-coverage.xcresult
      ruby Scripts/generate_coverage_badge.rb /tmp/OTFMagicBox-coverage.xcresult --target OTFMagicBox.app --output badges/coverage.svg

    The first form writes a badge from a known percentage.
    The second form reads line coverage from an Xcode .xcresult bundle using xcrun xccov.
  USAGE
end

def parse_args(argv)
  options = {
    output: DEFAULT_OUTPUT,
    target: DEFAULT_TARGET,
    label: DEFAULT_LABEL
  }

  input = nil
  until argv.empty?
    arg = argv.shift
    case arg
    when "-h", "--help"
      puts usage
      exit 0
    when "--output"
      options[:output] = argv.shift || abort("Missing value for --output")
    when "--target"
      options[:target] = argv.shift || abort("Missing value for --target")
    when "--label"
      options[:label] = argv.shift || abort("Missing value for --label")
    else
      abort("Unexpected argument: #{arg}") if input

      input = arg
    end
  end

  abort(usage) unless input

  [input, options]
end

def percentage_input?(input)
  input.match?(/\A\d+(?:\.\d+)?%?\z/)
end

def coverage_from_percentage(input)
  input.delete_suffix("%").to_f
end

def coverage_from_xcresult(path, target_name)
  abort("Coverage result not found: #{path}") unless File.exist?(path)

  stdout, stderr, status = Open3.capture3(
    "xcrun",
    "xccov",
    "view",
    "--report",
    "--json",
    "--only-targets",
    path
  )
  abort("Unable to read coverage from #{path}:\n#{stderr}") unless status.success?

  data = JSON.parse(stdout)
  targets = if data.is_a?(Array)
              data
            elsif data.is_a?(Hash)
              Array(data["targets"] || data["target"])
            else
              []
            end

  target = targets.find { |entry| entry["name"] == target_name } ||
           targets.find { |entry| entry["name"].to_s.include?(target_name) }

  unless target
    available = targets.map { |entry| entry["name"] }.compact.join(", ")
    abort("Target '#{target_name}' not found in coverage report. Available targets: #{available}")
  end

  line_coverage = target.fetch("lineCoverage")
  line_coverage <= 1 ? line_coverage * 100 : line_coverage
end

def badge_color(coverage)
  case coverage
  when 90.. then "#4c1"
  when 80...90 then "#97ca00"
  when 60...80 then "#dfb317"
  when 40...60 then "#fe7d37"
  else "#e05d44"
  end
end

def text_width(text)
  10 + (text.length * 7)
end

def badge_svg(label:, message:, color:)
  label_width = text_width(label)
  message_width = text_width(message)
  total_width = label_width + message_width
  label_x = label_width / 2.0
  message_x = label_width + (message_width / 2.0)

  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="#{total_width}" height="20" role="img" aria-label="#{CGI.escapeHTML(label)}: #{CGI.escapeHTML(message)}">
      <title>#{CGI.escapeHTML(label)}: #{CGI.escapeHTML(message)}</title>
      <linearGradient id="s" x2="0" y2="100%">
        <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
        <stop offset=".1" stop-color="#aaa" stop-opacity=".1"/>
        <stop offset=".9" stop-color="#000" stop-opacity=".3"/>
        <stop offset="1" stop-color="#000" stop-opacity=".5"/>
      </linearGradient>
      <clipPath id="r">
        <rect width="#{total_width}" height="20" rx="3" fill="#fff"/>
      </clipPath>
      <g clip-path="url(#r)">
        <rect width="#{label_width}" height="20" fill="#555"/>
        <rect x="#{label_width}" width="#{message_width}" height="20" fill="#{color}"/>
        <rect width="#{total_width}" height="20" fill="url(#s)"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
        <text x="#{label_x}" y="15" fill="#010101" fill-opacity=".3">#{CGI.escapeHTML(label)}</text>
        <text x="#{label_x}" y="14">#{CGI.escapeHTML(label)}</text>
        <text x="#{message_x}" y="15" fill="#010101" fill-opacity=".3">#{CGI.escapeHTML(message)}</text>
        <text x="#{message_x}" y="14">#{CGI.escapeHTML(message)}</text>
      </g>
    </svg>
  SVG
end

input, options = parse_args(ARGV)
coverage = percentage_input?(input) ? coverage_from_percentage(input) : coverage_from_xcresult(input, options[:target])
coverage = coverage.clamp(0, 100)
message = "#{format('%.1f', coverage)}%"
svg = badge_svg(label: options[:label], message: message, color: badge_color(coverage))

FileUtils.mkdir_p(File.dirname(options[:output]))
File.write(options[:output], svg)

puts "Updated #{options[:output]} with #{options[:label]} #{message}"
