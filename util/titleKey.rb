# Title key generation (used in deduping)

# Common English stop-words
$stopwords = Set.new(("a an the of and to in that was his he it with is for as had you not be her on at by which have or " +
                      "from this him but all she they were my are me one their so an said them we who would been will no when").split)

# Transliteration tables -- a cheesy but easy way to remove accents without requiring a Unicode gem
$transFrom = "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽ" +
             "ľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž"
$transTo   = "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlL" +
             "lLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"

###################################################################################################
# Remove accents from a string
def transliterate(str)
  str.tr($transFrom, $transTo)
end

###################################################################################################
# Generate a sortable title key for an item (useful for finding groups of similar titles)
def calcTitleKey(title)
  title or return ''

  # Remove HTML-like elements, normalize spaces, convert to lower case.
  tmp = title.gsub(/&lt[;,]/, '<').gsub(/&gt[;,]/, '>').gsub(/&#?\w+[;,]/, '')
  tmp = tmp.gsub(%r{</?\w[^>]+>}, ' ')
  tmp = tmp.gsub(/\s\s+/,' ').strip

  # Break it into words, and remove the stop words.
  key = transliterate(tmp).downcase.gsub(/[^a-z0-9 ]/, ' ').split.reject{ |w| $stopwords.include?(w) }.join(" ")

  # If we ended up keeping at least half the (primary) title, that's the key
  key.length >= (tmp.length/2) and return key

  # Otherwise, use a simpler, safer method. This is needed e.g. for titles that are all non-latin characters, or
  # all stop words like "To Be Or Not To Be" (a real title!)
  tmp.downcase
end
