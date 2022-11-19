# frozen_string_literal: true

class TranslationService::EasyNMT < TranslationService
  def initialize(base_url, force_language_detection)
    super()

    @base_url = base_url
    @force_language_detection = force_language_detection
  end

  def translate(text, source_language, target_language)
    request(text, source_language, target_language).perform do |res|
      case res.code
      when 200...300
        transform_response(res.body_with_limit, source_language)
      else
        raise UnexpectedResponseError
      end
    end
  end

  private

  def request(text, source_language, target_language)
    source_language = nil if @force_language_detection else source_language.presence
    body = Oj.dump(text: text, source_lang: source_language,
                   target_lang: target_language, perform_sentence_splitting: true)
    req = Request.new(:post, "#{@base_url}/translate", body: body)
    req.add_headers('Content-Type': 'application/json')
    req
  end

  def transform_response(str, source_language)
    json = Oj.load(str, mode: :strict)

    raise UnexpectedResponseError unless json.is_a?(Hash)

    Translation.new(text: json['translated'], detected_source_language: json.dig('detected_langs', 0), provider: 'EasyNMT')
  rescue Oj::ParseError
    raise UnexpectedResponseError
  end
end
