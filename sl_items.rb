class SL_item
  # Base class for SL Items
  # Subclasses must implement self.pattern

  attr_accessor :number, :link, :short_description

  def initialize(number, link, short_description)
    @number = number
    @link = link
    @short_description = short_description
  end

  def self.scan_for_matches message
    matches = message.scan(self.pattern).uniq.each { |m| m.upcase! }
    return matches.uniq # in case we had some strange capitalization before the upcase!
  end
end

# Set patterns for kb's here and use the superclass method for scanning
class Knowledge < SL_item
  def self.table
    'kb_knowledge'
  end

  def self.link sys_id
    return "https://umichprod.service-now.com/kb_view_customer.do?sysparm_article=#{sys_id}"
  end

  def self.pattern
    /[kK][bB]\d{7}\b/
  end
end

class Incident < SL_item
  def self.table
    'incident'
  end

  def self.link sys_id
    return "https://umichprod.service-now.com/nav_to.do?uri=incident.do?sys_id=#{sys_id}"
  end

  def self.pattern
    /[iI][nN][cC]\d{7}\b/
  end
end