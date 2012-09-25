module Garb
  module Management
    class Feed
      BASE_URL = "https://www.google.com/analytics/feeds/datasources/ga"
      ENTRIES_PER_FEED = 1000 # default numbers from GA v2.4

      attr_reader :request

      def initialize(session, path, params = {} )
        @session ||= session
        @path ||= path
        @request = DataRequest.new(session, BASE_URL+path, params )
      end 

      def parsed_response
        @parsed_response ||= Crack::XML.parse(response.body)
      end

      def entries
        entries = []
        # possible to have nil entries, yuck
        entries = single_page_entries
        # find more results if entries are more then 1000
        if total_results > ENTRIES_PER_FEED
          total_pages = (total_results.to_f / ENTRIES_PER_FEED.to_f ).ceil
          (1..total_pages).each do |i|
            feed = Feed.new( @session, @path, { 'start-index' => i*ENTRIES_PER_FEED })
            entries += feed.single_page_entries
          end
        end
        
        entries
      end
      
      def single_page_entries 
        entries = parsed_response ? [parsed_response['feed']['entry']].flatten.compact : []
      end 
      
      def total_results
        parsed_response ? parsed_response['feed']['openSearch:totalResults'].to_i : 0 
      end

      def response
        @response ||= request.send_request
      end
    end
  end
end
