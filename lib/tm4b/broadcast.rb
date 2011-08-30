require 'rexml/document'

module TM4B
   class Broadcast
      attr_reader :recipients
      def recipients=(recipients)
         if String === recipients
            recipients = [recipients]
         end

         @recipients = recipients.map {|r| r.gsub(/\D+/, '') }
      end

      attr_reader :originator
      def originator=(originator)
         originator = originator.to_s

         if (1..11).include? originator.length
            @originator = originator
         else
            raise "originator must be between 1 and 11 characters long"
         end
      end

      attr_reader :encoding
      def encoding=(encoding)
         if Protocol::EncodingTypes.include?(encoding)
            @encoding = encoding
         else
            raise "invalid encoding: #{encoding}"
         end
      end

      attr_reader :split_method
      def split_method=(method)
         if Protocol::SplitMethods.keys.include?(method)
            @split_method = method
         else
            raise "invalid splitting method: #{method}"
         end
      end

      attr_accessor :message, :route, :simulated

      # response variables
      attr_accessor :broadcast_id, :recipient_count, :balance_type, :credits, :balance, :neglected

      def initialize
         @encoding = :unicode
         @split_method = :concatenation_graceful
      end

      def raw_response=(body)
         # parse the response body into an XML document
         document = REXML::Document.new(body)

         # use XPath to parse the values from the response
         @broadcast_id    = REXML::XPath.first(document, '/result/broadcastID/child::text()').value
         @recipient_count = REXML::XPath.first(document, '/result/recipients/child::text()').value
         @credits      = REXML::XPath.first(document, '/result/credits/child::text()').value.to_f
         @balance      = REXML::XPath.first(document, '/result/balance/child::text()').value.to_f
         @balance_type = REXML::XPath.first(document, '/result/balanceType/child::text()').value
         @neglected    = REXML::XPath.first(document, '/result/neglected/child::text()').value
      end

      #
      # Returns a presentation of the broadcast variables for transmission to 
      # the TM4B API.  Does not include the username and password variables.
      #
      def parameters
         params = {
            "version"      => "2.1",
            "type"         => "broadcast",
            "to"           => recipients.join("|"),
            "from"         => originator,
            "msg"          => message,
            "data_type"    => encoding.to_s,
            "split_method" => Protocol::SplitMethods[split_method],
         }

         params["route"] = route if route
         params["sim"] = "yes" if simulated

         params
      end
   end
end