# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default)

class Layout < Phlex::HTML
  def initialize(title:, home: false)
    @title = title
    @home = home
  end

  def view_template
    doctype
    html(lang: "en") do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
        meta(name: "description", content: "Jan Dudulski personal site")

        link(type: "application/atom+xml", rel: "alternate", href: "/feed.xml", title: "~dudulski")

        style do
          safe(<<~CSS)
          blockquote {
              p::before {
                  content: "“";
              }
              p::after {
                  content: "”";
              }
          }
          article {
              section::after {
                  content: "∎";
              }
          }
          header {
              h1 > a {
                  color: #000;
                  text-decoration: none;
              }

              nav {
                  border-width: 1px 0;
                  border-style: solid;
                  border-color: #666;
                  padding: 0.5em 0;

                  display: flex;
                  flex-direction: row;
                  gap: 1em;

                  a {
                      text-decoration: none;
                  }
                  a:visited { color: #3300FF; }
              }
          }
          main {
            li {
                time::before {
                    content: "[";
                }
                time::after {
                    content: "]";
                }
                time {
                    margin-right: 0.5em;
                    color: #666;
                }
                a { text-decoration: none; }
                a:hover { text-decoration: underline; }

                line-height: 1.5em;
            }
          }
          body > footer::before {
              text-align: center;
              content: "❦";
              display: block;
              font-size: 2em;
              margin: 0.5em 0;
          }
          CSS
        end

        title { @title }
      end
      body do
        header do
          h1 do
            a(href: "/") { "Jan Dudulski" }
          end

          nav do
            a(href: "/gpg.txt") { "GNU Privacy Guard" }
            a(href: "https://github.com/jandudulski", rel: "me") { "GitHub" }
            a(href: "https://bsky.app/profile/jan.dudulski.pl", rel: "me") { "Bluesky" }
            a(href: "https://ruby.social/@jandudulski", rel: "me") { "Mastodon" }
            a(href: "https://www.linkedin.com/in/jandudulski/", rel: "me") { "Linkedin" }
            a(href: "/rss.xml") { "RSS" }
          end

          if @home
            blockquote do
              p { safe("For myself, I am an optimist &mdash; it does not seem to be much use being anything else.") }
            end
            b { safe("&mdash; Winston Leonard Spencer Churchill") }

            blockquote do
              p { "Pass on what you have learned. Strength. Mastery. But weakness, folly, failure also. Yes, failure most of all. The greatest teacher, failure is. Luke, we are what they grow beyond. That is the true burden of all masters." }
            end
            b { safe("&mdash; Master Yoda") }
          end
        end

        yield

        footer do
          p do
            plain("Horses thanks to ")
            a(href: "https://render.com") { "Render" }
            plain(" ❤")
          end
        end
      end
    end
  end
end

class NotFoundView < Phlex::HTML
  def initialize
    @layout = Layout.new(title: "~/404")
  end

  def view_template
    render @layout do
      h1 { "404" }
      article do
        p { "Page not found" }
      end
    end
  end
end

class HomeView < Phlex::HTML
  def initialize(entries:)
    @layout = Layout.new(title: "~dudulski", home: true)
    @entries = entries
  end

  def view_template
    render @layout do
      main do
        h1 { "Entries" }
        ul do
          @entries.reverse_each do |entry|
            li do
              time { entry.formatted_date }
              a(href: entry.url) { entry.title }
            end
          end
        end
      end
    end
  end
end

class EntryView < Phlex::HTML
  def initialize(entry:)
    @entry = entry
    @layout = Layout.new(title: "~/#{entry.title}")
  end

  def view_template
    render @layout do
      article do
        header do
          h1 { @entry.title }
        end

        section do
          markdown(@entry.content)
        end

        footer do
          h2 { @entry.formatted_date }
        end
      end
    end
  end

  private

  def markdown(content)
    raw safe(Kramdown::Document.new(content, input: "GFM").to_html)
  end
end

Entry = Decant.define(dir: "posts", ext: "md") do
  frontmatter :title, :url, :timestamp

  def formatted_date
    date = Time.parse(timestamp)

    if date.day == 1 || date.day == 21 || date.day == 31
      date.strftime("%b %est, %Y")
    elsif date.day == 2 || date.day == 22
      date.strftime("%b %end, %Y")
    elsif date.day == 3 || date.day == 23
      date.strftime("%b %erd, %Y")
    else
      date.strftime("%b %eth, %Y")
    end
  end
end

class App < Roda
  plugin :public

  route do |r|
    r.public

    r.get "404.html" do
      NotFoundView.call
    end

    r.get Integer, Integer, Integer, String do |year, month, day, slug|
      entry = Entry.find("#{year}-#{"%02d" % month}-#{day}-#{slug}")
      EntryView.new(entry: entry).call
    end

    r.get "feed.xml" do
      RSS::Maker.make("atom") do |maker|
        maker.channel.author = "Jan Dudulski"
        maker.channel.updated = Time.now
        maker.channel.id = "https://dudulski.pl/"
        maker.channel.links.new_link.tap do |link|
          link.href = "https://dudulski.pl/feed.xml"
          link.rel = "self"
        end
        maker.channel.title = "dudulski.pl"

        Entry.glob("*").each do |entry|
          maker.items.new_item do |item|
            item.link = "https://dudulski.pl#{entry.url}"
            item.title = entry.title
            item.updated = entry.timestamp
            item.content.type = "xhtml"
            item.content.xml = Kramdown::Document.new(entry.content, input: "GFM").to_html
          end
        end
      end.to_s
    end

    r.root do
      entries = Entry.glob("*")
      HomeView.new(entries: entries).call
    end
  end
end
