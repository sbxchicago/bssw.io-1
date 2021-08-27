# frozen_string_literal: true

class Searchable < SiteItem
  self.table_name = 'site_items'

  before_save :set_search_text
  def self.prepare_strings(string)
    if string.match(Regexp.new('"[^"]*"'))
      [[string.gsub('"', '')]]
    elsif string.match(Regexp.new("'[^']*'"))
      [[string.gsub("'", '')]]
    else
      lem = Lemmatizer.new
      string.split(' ').map do |str|
        [str, lem.lemma(str), str.stem].uniq
      end
    end
  end

  def self.order_results(words, results)
    word_array = []
    words.flatten.uniq.each do |str_var|
      unless str_var.blank?
        str_var = Regexp.escape(sanitize_sql_like(str_var))
        word_array << "name REGEXP \"#{Regexp.escape((str_var))}\" DESC"
      end
    end
    results.order(
      Arel.sql("field (type, 'WhatIs', 'HowTo', 'Resource', 'BlogPost', 'Event') ASC, #{word_array.join(',')}")
    )
  end

  def self.perform_search(words, page, preview)
    o_results = preview ? SiteItem.preview.displayed : SiteItem.published.displayed
    results = order_results(
      words, get_word_results(words, o_results)
    )
    Fellow.perform_search(
      words, page
    ) + results
  end

  def self.get_word_results(words, results)
    word_results = nil
    words.each do |word|
      word.flatten.uniq.each do |str_var|
        relation = results.where(Arel.sql(word_str(str_var)))
        word_results = word_results ? word_results.or(relation) : relation
      end
      results = results.merge(word_results)
    end
    results
  end

  def self.word_str(str_var)
    str_var = Regexp.escape(sanitize_sql_like(str_var))
    "search_text REGEXP \"([\\W]*|^)#{str_var}\" or search_text REGEXP \"#{str_var}([\\W]*|$)\""
  end

  def set_search_text
    self.search_text =
      ActionController::Base.helpers.strip_tags(
        "#{content} #{try(:author_list)} #{name} #{try(:description)} #{try(:location)} #{try(:organizers)}"
      )
    true
  end
end
