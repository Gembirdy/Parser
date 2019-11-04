# ruby parser.rb https://www.petsonic.com/snacks-huesos-para-perros/ results
require 'csv'
require 'curb'
require 'nokogiri'

if !ARGV[0].nil? && !ARGV[1].nil?

    url = ARGV[0]
    file_name = "#{ARGV[1]}.csv"

    items = []
    file_path = "/home/gembird/Parser_profitero/#{file_name}.csv"
    products_per_page = 25
    # url = 'https://www.petsonic.com/snacks-huesos-para-perros/'

    http = Curl.get(url)
    html = Nokogiri::HTML(http.body_str)

    total_products = (html.xpath("//span[@class='heading-counter']/text()").to_s)[0..1].to_i
    puts "products found: #{total_products}"

    total_pages = (total_products / products_per_page.to_f).ceil
    puts "pages found: #{total_pages}\n"

    current_page = 1
    while current_page <= total_pages do
        
        if current_page == 1
            ur = url 
        else
            ur = "#{url}?p=#{current_page}"
        end

        puts "\nDownloading #{ur} with Curl" 
        http = Curl.get(ur)
        puts "Scrapping #{ur} with Nokogiri"
        html = Nokogiri::HTML(http.body_str)

        puts 'Collecting links of products...'
        links = html.xpath("//a[@class='product-name']/@href")
        
        puts "Found #{links.count} links on page #{current_page}: "
        links.each do |link|
            unparsed_page = Curl.get(link)
            parsed_page = Nokogiri::HTML(unparsed_page.body_str)

            product = {
                :title => parsed_page.xpath("//h1[@class='product_main_name']/text()"),
                :image_url => parsed_page.xpath("//img[@id='bigpic']/@src"),
                :weights => parsed_page.xpath("//span[@class='radio_label']/text()"),
                :prices => parsed_page.xpath("//span[@class='price_comb']/text()")
            }
            puts "  #{product[:title]} on page #{current_page}"


            product[:prices].each_with_index do |price, index|
                item = {
                    :name => "#{product[:title]} - #{product[:weights][index]}", 
                    :price => price,
                    :image => product[:image_url]
                }
                # puts index
                items << item
            end
                
        end

        current_page += 1
    end

    puts "writing to #{file_name}.csv"
    lines_count = 0
    CSV.open(file_name, 'wb') do |csv|
        items.each do |item|
            csv << [item[:name], item[:price], item[:image]]
            lines_count += 1
        end
    end
    
    puts "Created #{lines_count} records in #{file_path}"

else
    puts 'Enter ARGV params'
end