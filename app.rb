# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default)

class Layout < Phlex::HTML
  def initialize(title:)
    @title = title
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
        yield

        footer do
          dl do
            dt { "GNU Privacy Guard" }
            dd do
              a(href: "/gpg.txt") { "Public gpg key" }
            end

            dt { "GitHub" }
            dd do
              a(href: "https://github.com/jandudulski", rel: "me") { "github.com/jandudulski" }
            end

            dt { "Bluesky" }
            dd do
              a(href: "https://bsky.app/profile/jan.dudulski.pl", rel: "me") { "@jan.dudulski.pl" }
            end

            dt { "Mastodon" }
            dd do
              a(href: "https://ruby.social/@jandudulski", rel: "me") { "@jandudulski@ruby.social" }
            end

            dt { "Linkedin" }
            dd do
              a(href: "https://www.linkedin.com/in/jandudulski/", rel: "me") { "linkedin.com/in/jandudulski" }
            end
          end

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
    @layout = Layout.new(title: "~dudulski")
    @entries = entries
  end

  def view_template
    render @layout do
      header do
        blockquote do
          p { safe("For myself, I am an optimist &mdash; it does not seem to be much use being anything else.") }
        end
        b { safe("&mdash; Winston Leonard Spencer Churchill") }

        blockquote do
          p { "Pass on what you have learned. Strength. Mastery. But weakness, folly, failure also. Yes, failure most of all. The greatest teacher, failure is. Luke, we are what they grow beyond. That is the true burden of all masters." }
        end
        b { safe("&mdash; Master Yoda") }
      end

      main do
        h1 { "Entires" }
        @entries.each do |entry|
          h2 do
            plain(entry.formatted_date)
            a(href: "/2017/09/25/noestimates") { entry.title }
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
      header do
        a(href: "/") { "Back" }
      end

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

Entry = Decant.define(dir: "src/_posts", ext: "md") do
  frontmatter :title, :timestamp

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
        maker.channel.about = "Personal site by Jan Dudulski"
        maker.channel.title = "dudulski.pl"

        Entry.glob("*").each do |entry|
          maker.items.new_item do |item|
            item.link = "https://dudulski.pl/#{entry.slug}"
            item.title = entry.title
            item.updated = entry.timestamp
            item.content.content = Kramdown::Document.new(entry.content, input: "GFM").to_html
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
