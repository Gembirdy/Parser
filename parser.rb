require 'csv'
require 'curb'
require 'nokogiri'

def download_page(link) 
    http = Curl.get(link)
    Nokogiri::HTML(http.body_str)
end

if !ARGV[0].nil? && !ARGV[1].nil?
    url = ARGV[0]
    file_name = "#{ARGV[1]}.csv"

    items = []
    current_path = File.dirname(__FILE__)
    file_path = current_path + file_name
    products_per_page = 25

    puts "\nDownloading #{url} with Curl" 
    puts "Scrapping #{url} with Nokogiri"
    html = download_page(url)

    total_products = (html.xpath("//span[@class='heading-counter']/text()").to_s)[0..1].to_i
    puts "products found: #{total_products}"

    total_pages = (total_products / products_per_page.to_f).ceil
    puts "pages found: #{total_pages}\n"

    (1..total_pages).each do |current_page|    
        current_page == 1 ? ur = url : ur = "#{url}?p=#{current_page}"

        puts 'Collecting links of products...'
        html = download_page(ur)

        links = html.xpath("//a[@class='product-name']/@href")
        puts "Found #{links.count} links on page #{current_page}: "

        links.each do |link|
            parsed_page = download_page(link)
            product = {
                :title => parsed_page.xpath("//h1[@class='product_main_name']/text()"),
                :image_url => parsed_page.xpath("//img[@id='bigpic']/@src"),
                :weights => parsed_page.xpath("//span[@class='radio_label']/text()"),
                :prices => parsed_page.xpath("//span[@class='price_comb']/text()")
            }
            puts "  #{product[:title]}"

            product[:prices].each_with_index do |price, index|
                item = {
                    :name => "#{product[:title]} - #{product[:weights][index]}", 
                    :price => price.to_s.delete!('€/u '),
                    :image => product[:image_url]
                }
                items << item
            end
        end
    end

    puts "writing to #{file_name}..."
    lines_count = 0
    CSV.open(file_name, 'wb') do |csv|
        csv << %w[Name Price Image]
        items.each do |item|
            csv << [item[:name], item[:price], item[:image]]
            lines_count += 1
        end
    end
    puts "Created #{lines_count} records in #{file_path}"
else
    puts 'Enter ARGV params'
end