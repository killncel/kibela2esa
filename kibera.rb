require 'front_matter_parser'

module Kibela
  TEAM = 'unasuke'
  TITLE_PATTERN = %r[\A.*/kibela-#{TEAM}-\d+/(?<kind>wikis|blogs)/(?<path>[[:print:]]*/)(?<id>\d)+-(?<name>[[:print:]]*)\.md\z]

  class Note
    attr_accessor :name, :category, :body, :frontmatter

    def initialize(file)
      raise ArgumentError unless file.is_a?(File)
      regexp = TITLE_PATTERN.match(file.path)
      markdown = FrontMatterParser::Parser.new(:md).call(file.read)

      @name = regexp[:name]
      @category = regexp[:path]
      @kind = regexp[:kind].to_sym
      @id = regexp[:id].to_i
      @body = markdown.content
      @frontmatter = markdown.front_matter
    end

    def blog?
      @kind == :blog
    end

    def wiki?
      @kind == :wikis
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
