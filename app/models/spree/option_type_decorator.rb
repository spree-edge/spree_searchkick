module Spree::OptionTypeDecorator
  def self.prepended(base)
    base.scope :filterable, -> { where(filterable: true) }
  end

  def filter_name
    name.downcase.to_s
  end
end

Spree::OptionType.prepend(Spree::OptionTypeDecorator)
