require 'front_matter_parser'
require 'nokogiri'

module Kibela
  TEAM = 'unasuke'
  TITLE_PATTERN = %r[\A.*/kibela-#{TEAM}-\d+/(?<kind>wikis|blogs)/(?<path>[[:print:]]*/)(?<id>\d)+-(?<name>[[:print:]]*)\.md\z]
  ATTACHMENT_PATTERN = %r[^(\.\./)*attachments/(?<attachment_name>\d+\.png)]

  class Note
    attr_accessor :name, :category, :body, :frontmatter, :author, :comments, :response

    def initialize(file)
      raise ArgumentError unless file.is_a?(File)
      regexp = TITLE_PATTERN.match(file.path)
      markdown = FrontMatterParser::Parser.new(:md).call(file.read)

      @name = regexp[:name]
      @category = regexp[:path].delete_suffix('/')
      @kind = regexp[:kind].to_sym
      @id = regexp[:id].to_i
      @body = markdown.content
      @frontmatter = markdown.front_matter
      @author = @frontmatter['author'].delete_prefix('@')
      @comments = @frontmatter['comments'].map { |c| Comment.new(c) }
    end

    def blog?
      @kind == :blogs
    end

    def wiki?
      @kind == :wikis
    end

    def wip?
      %r[wip]i.match?(@name)
    end

    def replace_attachment_names(attachment_list)
      parsed_body = Nokogiri::HTML(@body)
      parsed_body.css('img').map do |elem|
        match = ATTACHMENT_PATTERN.match(elem.attributes['src'].value)
        # 文中に出現するkibelaの画像URLをesaの画像URLに置換する
        @body.gsub!(elem.attributes['src'], attachment_list[match['attachment_name']].esa_path) if match
      end
    end

    def esa_number
      @response.body['number']
    end
  end

  class Attachment
    attr_accessor :name, :path

    def initialize(file)
      raise ArgumentError unless file.is_a?(File)

      @name = File.basename(file.path)
      @path = file.path
    end
  end
end
