
class Hash
  # Light extension to hash to add indifferent fetching. Meant to be more
  # lightweight than depending on ActiveSupport for HashWithIndifferentAccess.
  def indifferent_fetch(key, *extra)
    if key.class == Symbol
      self.fetch(key, self.fetch(key.to_s, *extra))
    else
      self.fetch(key, self.fetch(key.to_sym, *extra))
    end
  end
end
