require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'psych'
require 'net/http'

class PluginVersionScanner
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Connection" => "keep-alive",
  }.freeze

  def initialize(config, target_url)
     # Initializes the scanner with configuration and target URL.
    @config = load_config(config)
    @target_url = target_url
  end

  def run
     # Starts the scanning process..
    html = fetch_html()
    search_patterns(html, @config)
  end

  private


  def fetch_html()
    # Fetch the HTML source code of a site.
  
    Nokogiri::HTML(URI.open(@target_url, HEADERS), nil, "UTF-8")
  end
  
  def fetch_content_from_url(url = @target_url)
    # Fetches the content from a given URL
  
    URI.open(url, HEADERS).read
  rescue StandardError
    nil
  end
  

  def fetch_readme_content(plugin_slug, path)
    # Fetches the README content for a given plugin from its directory on a website.
    #
    # @param plugin_slug [String] The slug of the plugin.
    # @param path [String] The relative path to the README file.

    readme_url = "#{@target_url}/wp-content/plugins/#{plugin_slug}/#{path}"
    fetch_content_from_url(readme_url)
  rescue StandardError
    nil
  end

  def load_config(file_path)
    # Loads the YAML file.
    #
    # @param file_path [String] The path to the YAML file.

    Psych.safe_load(File.read(file_path), permitted_classes: [Regexp])
  end

  def from_stable_tag(body)
    # Extracts the stable tag or version number from a given text body.
    #
    # @param body [String] The text body from which to extract the version number.

    return unless body =~ /\b(?:stable tag|version):\s*(?!trunk)([0-9a-z.-]+)/i
    number = Regexp.last_match[1]
    number if /[0-9]+/.match?(number)
  end

  def get_version(obj, type, content, pattern, plugin_name)
    # Tries to find the version of the plugin.
    #
    # @param obj [Hash] the configuration object for the plugin.
    # @param type [String] the type of check being performed.
    # @param content [String] the content to search within.
    # @param pattern [Regexp] the pattern to match for the version.
    # @param plugin_name [String] the name of the plugin.

    if obj[type].key?("version") && pattern
      content[pattern, 1]
    elsif obj.key?("Readme") && obj["Readme"].key?("path")
      readme_content = fetch_readme_content(plugin_name, obj["Readme"].key?("path"))
      from_stable_tag(readme_content) ? readme_content : nil
    else
      nil
    end
  end

  def collect_plugins(html_content, config, plugin_name, type, xpath_default = nil)
    # Extracts and prints the version of a plugin based on the specified content and configuration.
    #
    # @param html_content [] The HTML document to search through.
    # @param config [Hash] The configuration hash containing patterns.
    # @param plugin_name [String] The name of the plugin being searched for.
    # @param type [String] The type of content being checked ("Comment", "MetaTag").
    # @param xpath_default [String] The default XPath expression to use.

    return unless config.key?(type)

    pattern = config[type].key?("pattern") ? Regexp.new(config[type]["pattern"]) : nil
    xpath = config[type]['xpath'] || xpath_default
    html_content.xpath(xpath).each do |node|
      content = node.text.strip

      next if pattern && !content.match?(pattern)

      version = get_version(config, type, content, pattern, plugin_name)
      puts "Plugin found!\033[32m #{plugin_name}\033[0m: #{version || "unknown"}"
    end
  end

  def Comments(html_content, config, plugin_name)
    # Extracts and prints version information for plugins found in comments.
    #
    # "//comment()" is used as an specific Xpath expression.

    collect_plugins(html_content, config, plugin_name, "Comment", "//comment()")
  end

  def MetaTag(html_content, config, plugin_name)
    # Extracts and prints version information for plugins found in meta tags.

    collect_plugins(html_content, config, plugin_name, "MetaTag")
  end

  def search_patterns(html_content, config)
    # Loop through the YAML file data and trigger functions.
    #
    # @param html_content [] The HTML document to search through.
    # @param config [Hash] The configuration hash containing patterns.

    config.each do |section, details|
      details.each do |plugin, plugin_details|
        Comments(html_content, plugin_details, plugin)
        MetaTag(html_content, plugin_details, plugin)
      end
    end
  end
end


if ARGV.length != 2
  puts "Use: #{$0} yml-file url"
  exit 1
end

scanner = PluginVersionScanner.new(ARGV[0], ARGV[1])
scanner.run
