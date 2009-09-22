require "digest/md5"

module WebmoneyAcceptor
  class << self
    def config
      @config ||= YAML.load_file(File.join(Rails.root, "config", "webmoney.yml"))[Rails.env]
    end
  end

  class InvalidTransaction < Exception
  end

  module ControllerExtension
    class Acceptor
      def initialize(controller)
        @controller = controller
      end

      def valid_payment?(secret = nil)
        secret = secret || params[:secret_key] || WebmoneyPayments.config["secret"]
        
        raise ArgumentError.new("WebMoney secret key is not provided") if secret.blank?

        params[:hash] = Digest::MD5.hexdigest(
          [
            params[:payee_purse],
            params[:payment_amount],
            params[:payment_no],
            params[:mode],
            params[:sys_invs_no],
            params[:sys_trans_no],
            params[:sys_trans_date],
            secret,
            params[:payer_purse],
            params[:payer_wm]
          ].join("")
        ).upcase
      end

      def params
        unless @params
          @params = HashWithIndifferentAccess.new

          @controller.params.each do |key, value|
            if key.starts_with?('LMI_')
              @params[key.gsub(/^LMI_/, "").downcase] = value
            end
          end
        end

        @params
      end

      def prerequest?
        params[:prerequest] == "1"
      end
      
      def currency
        "wm#{params[:payee_purse].first.downcase}".to_sym
      end
    end

    def webmoney
      @webmoney_acceptor ||= Acceptor.new(self)
    end
  end

  module ViewExtension
    def webmoney_payment_form(*args, &block)
      options = args.extract_options!
      amount  = args.pop
      wallet  = args.first || WebmoneyPayments.config["wallet"]

      raise ArgumentError.new("Webmoney wallet is not provided") if wallet.blank?

      result = form_tag("https://merchant.webmoney.ru/lmi/payment.asp", :method => "POST")
      result << hidden_field_tag(:LMI_PAYEE_PURSE, wallet)
      result << hidden_field_tag(:LMI_PAYMENT_AMOUNT, amount)

      options.each do |key, value|
        result << hidden_field_tag("LMI_#{key.to_s.upcase}", value)
      end

      result << capture(&block) if block_given?

      block_given? ? concat(result) : result
    end
  end
end
