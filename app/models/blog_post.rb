# frozen_string_literal: true

# a blog post
class BlogPost < SiteItem
  self.table_name = 'site_items'

  default_scope -> { order(published_at: 'desc') }

  # def url_slug
  #   'blog_posts'
  # end

  # extend FriendlyId
  # friendly_id :slug_candidates, use: %i[finders slugged scoped], scope: :rebuild_id

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
      self.hero_image_url = doc.at('img').try(:[], 'src')
      li.try(:remove)
    end
    hero.try(:remove)
  end
end
