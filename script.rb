require 'fileutils'
require 'pry'
require 'esa'
require 'logger'
require_relative './kibela'

ESA_TEAM = 'unasuke'
USER_MAPPING = [
  { kibela: 'unasuke', esa: 'unasuke' }
]

class Migrater
  attr_reader :notes, :attachment_list

  def initialize(kibela: , esa:)
    @logger = Logger.new(STDOUT)
    @client = Esa::Client.new(access_token: ENV['ESA_ACCESS_TOKEN'], current_team: ESA_TEAM)
  end

  def prepare
    @notes = Dir.glob("./kibela-unasuke-*/**/*.md").map do |path|
      File.open(path) do |f|
        Kibela::Note.new(f)
      end
    end

    @attachments = Dir.glob("./kibela-unasuke-*/attachments/*").map do |path|
      File.open(path) do |f|
        Kibela::Attachment.new(f)
      end
    end

    @attachment_list = {}
    @attachments.each do |a|
      @attachment_list[a.name] = a
    end

    self
  end

  def migrate(dry_run: true)
    prepare
    upload_attachments unless dry_run

    @notes.each do |note|
      request = note.esafy(@attachment_list)
      @logger.info request

      unless dry_run
        response = @client.create_post(request)
        note.response = response
        sleep 0.5
      end

      note.comments.each do |comment|
        request = comment.esafy(@attachment_list)
        @logger.info request

        unless dry_run
          @client.create_comment(note.esa_number, request)
          sleep 0.5
        end
      end
    end
  end

  def upload_attachments
    @attachments.each do |attachment|
      response = @client.upload_attachment(attachment.path)
      attachment.esa_path = response.body['attachment']['url']
      sleep 0.5
    end
  end
end

migrater = Migrater.new(kibela: 'unasuke', esa: 'unasuke')

binding.pry
