require 'front_matter_parser'
require 'nokogiri'

module Kibela
  TEAM = 'unasuke'
  TITLE_PATTERN = %r[\A.*/kibela-#{TEAM}-\d+/(?<kind>wikis|blogs)/(?<path>[[:print:]]*/)*(?<id>\d)+-(?<name>[[:print:]]*)\.md\z]
  ATTACHMENT_PATTERN = %r[^(?~http)(\.\./)*attachments/(?<attachment_name>\d+\.(png|JPG|jpg|jpeg|gif|PNG))]
  KIBELA_ESA_USER_MAP = {
    'unasuke' => 'unasuke'
  }

  class Note
    attr_accessor :name, :category, :body, :frontmatter, :author, :comments, :response

    def initialize(file)
      raise ArgumentError unless file.is_a?(File)
      regexp = TITLE_PATTERN.match(file.path)
      markdown = FrontMatterParser::Parser.new(:md).call(file.read)

      @name = regexp[:name]
      @category = "from_kibela/#{regexp[:path]}".delete_suffix('/')
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
        next unless elem.attributes['src']
        match = ATTACHMENT_PATTERN.match(elem.attributes['src'].value)
        # 文中に出現するkibelaの画像URLをesaの画像URLに置換する
        next unless match
        next unless attachment_list[match['attachment_name']]
        @body.gsub!(elem.attributes['src'], attachment_list[match['attachment_name']].esa_path) if match
      end
    end

    def esafy(attachment_list)
      replace_attachment_names(attachment_list)
      @category = 'blog' if blog?
      {
        post: {
          name: @name,
          body_md: @body,
          tags: [],
          category: @category,
          user: esafy_user_name(@author),
          wip: wip?,
          message: 'migrate from kibela',
        }
      }
    end

    def esafy_user_name(kibela_user)
      KIBELA_ESA_USER_MAP[kibela_user] || 'esa_bot'
    end

    def esa_number
      @response.body['number']
    end
  end

  class Comment
    def initialize(comment)
      @raw = comment
      @content = @raw['content']
      @user = @raw['user']
    end

    def replace_attachment_names(attachment_list)
      parsed_comment = Nokogiri::HTML(@content)
      parsed_comment.css('img').map do |elem|
        match = ATTACHMENT_PATTERN.match(elem.attributes['src'].value)
        @content.gsub!(elem.attributes['src'], attachment_list[match['attachment_name']].esa_path) if match
      end
    end

    def esafy_user_name(kibela_user)
      KIBELA_ESA_USER_MAP[kibela_user] || 'esa_bot'
    end

    def esafy(attachment_list)
      replace_attachment_names(attachment_list)
      {
        body_md: @content,
        user: esafy_user_name(@user)
      }
    end
  end

  class Attachment
    attr_accessor :name, :path, :esa_path

    def initialize(file)
      raise ArgumentError unless file.is_a?(File)

      @name = File.basename(file.path)
      @path = file.path
      @esa_path = 'dummy'
    end
  end
end
