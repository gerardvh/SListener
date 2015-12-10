class SL_item
  attr_accessor :number, :link, :short_description

  def initialize(number, link, short_description)
    @number = number
    @link = link
    @short_description = short_description
  end

  def self.scan_for_matches message
    message.scan(self.pattern).uniq.each { |m| m.upcase! }
  end
end

# Set patterns for kb's here and use the superclass method for scanning
class Knowledge < SL_item
  def self.pattern
    /[kK][bB]\d{7}\b/
  end
end

class Incident < SL_item
  def self.pattern
    /[iI][nN][cC]\d{7}\b/
  end
end