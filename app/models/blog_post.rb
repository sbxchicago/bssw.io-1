# frozen_string_literal: true

# a blog post
class BlogPost < Searchable
  self.table_name = 'site_items'

  default_scope -> { order(published_at: 'desc') }

  def related_posts
    posts = []
    topics.each do |topic|
      posts += BlogPost.where(rebuild_id: rebuild_id, publish: publish, preview: preview).with_topic(topic)
    end
    posts
  end

  def update_from_content(doc, rebuild)
    look_for_image(doc)
    super(doc, rebuild)
  end

  def look_for_image(doc)
    hero = doc.at("strong:contains('Hero Image')")
    return unless hero

    li = doc.at('li')

    if li
      caption = li.content.match(Regexp.new('\[(.*?)\]'))
      self.hero_image_caption = caption.try(:[], 1)
      self.hero_image_url = MarkdownUtility.modified_path(doc.at('img').try(:[], 'src'))
      li.try(:remove)
    end
    hero.try(:remove)
  end
end
