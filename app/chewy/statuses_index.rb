# frozen_string_literal: true

class StatusesIndex < Chewy::Index
  settings index: {
    refresh_interval: '15m',
    number_of_shards: '30',
    number_of_replicas: '0'
  }, analysis: {
    filter: {
      english_stop: {
        type: 'stop',
        stopwords: '_english_',
      },
      english_stemmer: {
        type: 'stemmer',
        language: 'english',
      },
      english_possessive_stemmer: {
        type: 'stemmer',
        language: 'possessive_english',
      },
    },
    tokenizer: {
      ja_ma_tokenizer: {
        type: 'sudachi_tokenizer',
        mode: 'search',
        discard_punctuation: 'true',
        resources_path: '/etc/elasticsearch/sudachi',
        settings_path: '/etc/elasticsearch/sudachi/sudachi.json'
      },
      ja_ngram_tokenizer: {
        type: 'nGram',
        min_gram: '2',
        max_gram: '3',
      },
    },
    analyzer: {
      content: {
        type: 'custom',
        tokenizer: 'ja_ma_tokenizer',
        filter: %w(
          sudachi_baseform
          cjk_width
          sudachi_part_of_speech
          sudachi_ja_stop
          lowercase
        ),
      },
      ngram: {
        type: 'custom',
        tokenizer: 'ja_ngram_tokenizer',
        filter: %w(
          cjk_width
          lowercase
        ),
      },
      uue: {
        tokenizer: 'uax_url_email',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
      },
    },
  }

  define_type ::Status.unscoped.kept.without_reblogs.includes(:media_attachments), delete_if: ->(status) { status.searchable_by.empty? } do
    crutch :mentions do |collection|
      data = ::Mention.where(status_id: collection.map(&:id)).where(account: Account.local, silent: false).pluck(:status_id, :account_id)
      data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
    end

    crutch :favourites do |collection|
      data = ::Favourite.where(status_id: collection.map(&:id)).where(account: Account.local).pluck(:status_id, :account_id)
      data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
    end

    crutch :reblogs do |collection|
      data = ::Status.where(reblog_of_id: collection.map(&:id)).where(account: Account.local).pluck(:reblog_of_id, :account_id)
      data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
    end

    crutch :bookmarks do |collection|
      data = ::Bookmark.where(status_id: collection.map(&:id)).where(account: Account.local).pluck(:status_id, :account_id)
      data.each.with_object({}) { |(id, name), result| (result[id] ||= []).push(name) }
    end

    root date_detection: false do
      field :id, type: 'long'
      field :account_id, type: 'long'

      field :text, type: 'text', value: ->(status) { [status.spoiler_text, Formatter.instance.plaintext(status)].concat(status.media_attachments.map(&:description)).concat(status.preloadable_poll ? status.preloadable_poll.options : []).join("\n\n") } do
        field :stemmed, type: 'text', analyzer: 'content'
        field :ngram, type: 'text', analyzer: 'ngram'
        field :uue, type: 'text', analyzer: 'uue'
      end

      field :searchable_by, type: 'long', value: ->(status, crutches) { status.searchable_by(crutches) }
    end
  end
end
