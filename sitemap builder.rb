require 'net/http'
require 'nokogiri'


def get_links(url)

    uri = URI(url)

    begin
        response = Net::HTTP.get_response(uri)
    rescue => exception
        return
    end


    if response.is_a?(Net::HTTPSuccess)
        links = []
        html =  response.body

        parsed_data = Nokogiri::HTML.parse(html)
        a_tags = parsed_data.xpath("//a")
        a_tags.each { |tag|
            links << tag[:href]
        }

        return links
    end

end

def get_root(url)
    uri = URI.parse(url)
    uri.scheme + "://" + uri.host
end

def get_scheme(url)
    URI.parse(url).scheme
end

def get_host(url)
    URI.parse(url).host
end

def get_page(link)
    l = link.split("/").reject {|c| c.empty? || c.strip.empty?}
    l.pop
end

def sitemap_builder
    print "Enter Root URl: "
    url = gets.chomp
    # url = "https://www.sitemaps.org/schemas/"

    viewed_links = []
    pages = []

    root = get_root(url)
    scheme = get_scheme(url)
    host = get_host(url)

    links = get_links(url)
    links = links.uniq

    print "Fetching"


    while !links.empty? do
        link = links.pop()


        if /^#.*/.match?(link) || /^javascript.*/.match?(link) || /^tel:[0-9]*/.match?(link)
            next
        elsif /^https?:\/\/.*/.match?(link)
            if get_scheme(link) != scheme
                next
            end
        elsif /^\/.*/.match?(link)
            link = root + link
        elsif /^\w*\.\w*$/.match?(link)
            link = root + "/" + link
        else
            next
        end

        if viewed_links.count(link) == 0 && get_host(link) == host && pages.count(get_page(link)) == 0

            pages << get_page(link)

            new_links = get_links(link)

            if new_links.is_a?(Array) && !new_links.empty?
                new_links.each{ |l|
                    print "."
                    if !Regexp.new("^http.*").match?(link)
                        links << link + "/" + l
                    else
                        links << l
                    end
                }
            end
            links = links.uniq  
            
            if new_links.is_a?(Array)
                viewed_links << link
            end
        end
    end
        
    print "\n"

    #xml generation
    builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset('xmlns' => url) {
            viewed_links.each { |l|
                xml.url {
                    xml.loc l
                }
    
            }
          
        }
    end
    puts builder.to_xml    

end

sitemap_builder
