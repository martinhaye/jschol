#!/usr/bin/env ruby

# This script attempts to find duplicate items in the repository

# Use bundler to keep dependencies local
require 'rubygems'
require 'bundler/setup'

# Run from the right directory (the parent of the tools dir)
Dir.chdir(File.dirname(File.expand_path(File.dirname(__FILE__))))

# Remainder are the requirements for this program
require 'date'
require 'digest'
require 'json'
require 'pp'
require 'sequel'
require 'set'
require 'time'
require_relative '../util/titleKey.rb'
require_relative '../util/xmlutil.rb'

# Make puts synchronous (e.g. auto-flush)
STDOUT.sync = true

# Mode to do only a subset, but quickly
$fastMode = ARGV.delete('--fast')

DATA_DIR = "/apps/eschol/erep/data"

# The main database we're working on
DB = Sequel.connect({
  "adapter"  => "mysql2",
  "host"     => ENV["ESCHOL_DB_HOST"] || raise("missing env ESCHOL_DB_HOST"),
  "port"     => ENV["ESCHOL_DB_PORT"] || raise("missing env ESCHOL_DB_PORT").to_i,
  "database" => ENV["ESCHOL_DB_DATABASE"] || raise("missing env ESCHOL_DB_DATABASE"),
  "username" => ENV["ESCHOL_DB_USERNAME"] || raise("missing env ESCHOL_DB_USERNAME"),
  "password" => ENV["ESCHOL_DB_PASSWORD"] || raise("missing env ESCHOL_DB_HOST") })

# Log for debugging
#File.exists?('dedupe.sql_log') and File.delete('dedupe.sql_log')
#DB.loggers << Logger.new('dedupe.sql_log')

# Model class for each table
require_relative './models.rb'

# We need to identify recurring series items and avoid grouping them. Best way seems to be just by title.
seriesTitles = [
  # Fairly generic stuff
  "About the Contributors",
  "Acknowledg(e?)ments",
  "Advertisement(s?)",
  "Author's Biographies",
  "(Back|End|Front) (Cover|Matter)",
  "(Books )?noted with interest",
  "Books Received",
  "Brief Notes on Recent Publications",
  "Call for Papers",
  "Conference Program",
  "Contents",
  "Contributors",
  "Cover",
  "(Editor's|Editors|Editors'|President's) (Introduction|Message|Note|Page)",
  "Editorial",
  "Editorial Notes",
  "Foreword",
  "(Forward |Reprise )?Editor's Note",
  "Full Issue",
  "Introduction",
  "Job announcements",
  "Letter from the Editors",
  "Legislative Update",
  "Masthead",
  "New Titles",
  "Preface",
  "Publications Received",
  "Review",
  "(The )?Table of Contents",
  "Thanks to reviewers",
  "Untitled",
  "Upcoming events",
  # Stuff that's likely specific to eScholarship
  "Beyond the Frontier II",
  "Conceiving a Courtyard",
  "Environmental Information Sources",
  "Índice",
  "Lider/ Poems",
  "Summary of the Research Progress Meeting",
  "Three pieces",
  "Two Poems",
  "Dissertation Abstracts",
  "Publications and Dissertations"
]
$seriesTitlesPat = Regexp.new("^(#{seriesTitles.join('|').downcase})$")

###################################################################################################
# Determine if the title is a likely series item
def isSeriesTitle(title)
  ft = transliterate(title).downcase.gsub(/^[\[\(]|[\)\]]$/, '').gsub(/\s\s+/, ' ').gsub('’', '\'').strip()
  return $seriesTitlesPat.match(ft)
end

###################################################################################################
def getShortArk(arkStr)
  arkStr =~ %r{^ark:/?13030/(qt\w{8})$} and return $1
  arkStr =~ /^(qt\w{8})$/ and return arkStr
  arkStr =~ /^\w{8}$/ and return "qt#{arkStr}"
  raise("Can't parse ark from #{arkStr.inspect}")
end

###################################################################################################
def arkToFile(ark, subpath, root = DATA_DIR)
  shortArk = getShortArk(ark)
  path = "#{root}/13030/pairtree_root/#{shortArk.scan(/\w\w/).join('/')}/#{shortArk}/#{subpath}"
  return path.sub(%r{^/13030}, "13030").gsub(%r{//+}, "/").gsub(/\bbase\b/, shortArk).sub(%r{/+$}, "")
end

###################################################################################################
def calcAuthorKeys(authors)
  Set.new(authors.map { |auth|
    # For "Martin Haye" use "Haye"; for "Haye, Martin" use "Haye"
    transliterate(auth).downcase.sub(/^[^,]+ ([^,]+)$/, '\1').gsub(/[^a-z]/,'')[0,4]
  })
end

###################################################################################################
# See if the candidate is compatible with the existing items in the group
def isCompatible(items, cand)
  candAuthKeys = cand[:authorKeys]
  return true if candAuthKeys.empty?
  ok = true
  ids = {}

  # Make sure the candidate overlaps at least one author of every pub in the set (except items
  # with no author keys). While we're at it, collect the IDs.
  items.each { |item|
    itemAuthKeys = item[:authorKeys]
    next if itemAuthKeys.empty?
    overlap = itemAuthKeys & candAuthKeys
    if overlap.empty?
      puts "No overlap: #{itemAuthKeys.to_a.join(',')} vs. #{candAuthKeys.to_a.join(',')}"
      ok = false
    end
    ids.merge! item[:ids]
  }

  # Make sure the candidate has no conflicting IDs
  cand[:ids].each { |type, id|
    if ids[type] && ids[type] != id
      next unless type =~ /doi|pmid|pmcid/ # these are the only show-stoppers; others less reliable
      puts "ID mismatch for type #{type.inspect}: #{id.inspect} vs #{ids[type].inspect}"
      ok = false
    end
  }

  # All done.
  return ok
end

###################################################################################################
# From https://stackoverflow.com/questions/8619785
def charDistance(s1, s2)
  d = {}
  (0..s1.size).each do |row|
    d[[row, 0]] = row
  end
  (0..s2.size).each do |col|
    d[[0, col]] = col
    end
  (1..s1.size).each do |i|
    (1..s2.size).each do |j|
      cost = 0
      if (s1[i-1] != s2[j-1])
        cost = 1
      end
      d[[i, j]] = [d[[i - 1, j]] + 1,
                   d[[i, j - 1]] + 1,
                   d[[i - 1, j - 1]] + cost
                  ].min
      #next unless @@damerau
      if (i > 1 and j > 1 and s1[i-1] == s2[j-2] and s1[i-2] == s2[j-1])
        d[[i, j]] = [d[[i,j]],
                     d[[i-2, j-2]] + cost
                    ].min
      end
    end
  end
  return d[[s1.size, s2.size]]
end

# Characters that are easily confused for each other by OCR programs
$sloppy1 = "I10OqmcDFZ85"
$sloppy2 = "lloogneoE2BS"

###################################################################################################
def sloppyCharDist(s1, s2)
  return charDistance(s1.tr($sloppy1, $sloppy2), s2.tr($sloppy1, $sloppy2))
end

###################################################################################################
# Calculate the words differing from str1 to str2
def wordDiff(str1, str2)
  return (Set.new(str1.split) ^ Set.new(str2.split)).to_a
end

###################################################################################################
def shouldGroupTitleKeys(tk1, tk2)
  !tk1 || !tk2 and return false
  tk1 == tk2 and return true
  d = wordDiff(tk1, tk2)
  d.size > 1 and return false  # more than 1 extra or missing word
  d.any?{ |w| w =~ /^[\divx]+$/ } and return false # difference in number (decimal or Roman numerals)
  sloppyCharDist(tk1, tk2) > 4 and return false
  return true
end

###################################################################################################
def processSingleton(itemInfo)
  # nothing yet
end

###################################################################################################
def tryRsync
  raw = `/usr/bin/rsync -av file1.tmp file2.tmp`
  nSent = nReceived = nil
  raw.split("\n").each { |line|
    line =~ /sent (\d+) bytes/ and nSent = $1.to_i
    line =~ /received (\d+) bytes/ and nReceived = $1.to_i
  }
  nSent && nReceived or raise("can't understand rsync output #{raw.inspect}")
  return nSent + nReceived
end

###################################################################################################
# Returns the % sameness of file1 to file2, using rsync as a proxy
def fileRsyncCompare(path1, path2)
  #puts "path1=#{path1} exist=#{File.exist?(path1)}"
  #puts "path2=#{path2} exist=#{File.exist?(path2)}"
  File.exist?(path1) && File.exist?(path2) or return 0.0
  FileUtils.cp path1, "file1.tmp"
  FileUtils.cp path1, "file2.tmp"
  size1 = File.size(path1)
  nullPatchSize = tryRsync
  FileUtils.cp path2, "file2.tmp"
  realPatchSize = tryRsync
  #puts "size1=#{size1} nullPatchSize=#{nullPatchSize} realPatchSize=#{realPatchSize}"
  return [100.0, [0.0, 100.0 - ((realPatchSize - nullPatchSize) * 100.0 / size1)].max].min
end

###################################################################################################
def stripCoords(fromPath, toPath)
  xml = fileToXML(fromPath)
  open(toPath, "w") { |io|
    xml.xpath(".//line").each { |lineEl|
      line = transliterate(lineEl.text).tr($sloppy1, $sloppy2).downcase
      io.puts line.gsub(/[^a-z0-9 ]/, ' ').gsub(/\s\s+/,' ').strip
    }
  }
end

###################################################################################################
def compareText(id1, id2)
  tc1 = arkToFile(id1, "rip/base.textCoords.xml")
  tc2 = arkToFile(id2, "rip/base.textCoords.xml")
  if File.exist? tc1
    if File.exist? tc2
      stripCoords(tc1, "tc1.txt")
      stripCoords(tc2, "tc2.txt")
      File.exist?("tc.diff") and File.delete("tc.diff")
      diffSize = `diff tc1.txt tc2.txt | egrep '^[<>]' | wc -l`.to_i
      tc1Size = `cat tc1.txt | wc -l`.to_i
      tc2Size = `cat tc2.txt | wc -l`.to_i
      sameRatio = 100.0 - (diffSize * 100.0 / (tc1Size+tc2Size))
      #puts "tc1Size=#{tc1Size} tc2Size=#{tc2Size} totSize=#{tc1Size+tc2Size} diffSize=#{diffSize}"
      #puts "sameRatio=#{sameRatio.round(2)}"
      return "text:#{sameRatio.round(2)}% "
    else
      return "text:yes:no "
    end
  elsif File.exist? tc2
    return "text:no:yes "
  end
  return ""
end

###################################################################################################
# Kinda obsolete
def compareFileCombos(subgroup)
  subgroup.combination(2).each { |item1, item2|
    print "      #{item1.id} vs #{item2.id}: "
    pdf1 = arkToFile(item1.id, "content/base.pdf")
    pdf2 = arkToFile(item2.id, "content/base.pdf")
    if File.exist? pdf1
      if File.exist? pdf2
        doText = true
        if File.size(pdf1) == File.size(pdf2)
          if FileUtils.compare_file(pdf1, pdf2)
            print "pdf:exact "
            doText = false
          else
            print "pdf:samesize "
          end
        else
          print "pdf:#{File.size(pdf1)}:#{File.size(pdf2)} "
        end
        if doText
          print compareText(item1.id, item2.id)
        end
      else
        print "pdf:yes:no "
      end
    elsif File.exist? pdf2
      print "pdf:no:yes "
    end

    ext1 = item1[:attrs]['pub_web_loc']
    ext2 = item2[:attrs]['pub_web_loc']
    if ext1
      if ext2
        if ext1 == ext2
          print "pubWebLoc:same "
        else
          print "pubWebLoc:different "
        end
      else
        print "pubWebLoc:yes:no"
      end
    elsif ext2
      print "pubWebLoc:no:yes"
    end

    puts
  }
end

###################################################################################################
def processTitleGroup(group)
   # Already singleton?
  if group.size == 1
    return processSingleton(group[0])
  end

  tks = Set.new(group.map { |info| info[:titleKey] })
  puts
  puts "Title group: #{tks.to_a.sort.join("\n             ")}"

  dates = Set.new(group.map { |info| info[:published] })
  puts "      dates: #{dates.to_a.sort.join(", ")}"

  itemIds = group.map { |info| info[:id] }
  puts "      items: #{itemIds.to_a.sort.join(", ")}"
  puts "      nItems: #{group.size}"

  # If 5 or more dates involved, it's probably a series title. Treat as singletons.
  # Likewise with too many items.
  if dates.size >= 5 || group.size >= 8
    puts "        ==> too many dates or items - treating as singletons (likely series title)"
    return group.map { |info| processSingleton(info) }
  end

  # If any series titles involved, treat as singletons.
  #if group.any?{ |info| isSeriesTitle(info[:title]) }
  #  puts "        ==> series title(s) - treating as singletons"
  #  return group.map { |info| processSingleton(info) }
  #end

  itemIds = group.map { |info| info[:id] }
  items = Hash[Item.where(id: itemIds).map{ |item|
    [item.id, item]
  }]
  ItemAuthor.where(item_id: itemIds).select(:item_id, Sequel.as(Sequel.lit("attrs->>'$.name'"), :name)).each { |rec|
    (items[rec.item_id][:authors] ||= []) << rec[:name]
  }
  items.each { |itemID, item|
    item[:authorKeys] = calcAuthorKeys(item[:authors] || [])
    item.attrs = JSON.parse(item.attrs)
    ids = {}
    item.attrs['doi'] and ids['doi'] = item.attrs['doi'].sub(/.*?10\./, '10.').strip  # normalize DOIs
    (item.attrs['local_ids'] || []).each { |pair|
      ids[pair['type']] = pair['id']
    }
    item[:ids] = ids

    pdfPath = arkToFile(item1.id, "content/base.pdf")
    if pdfPath.exist?
      item[:pdfPath] = pdfPath
      item[:pdfSize] = File.size(pdfPath)
    end
  }

  # Compute pairwise match scores
  pairScores = {}
  filePrints = {}
  group.combination(2).each { |item1, item2|
    scorePair(item1, item2, pairScores, filePrints)
  }

  todo = items.values
  while !todo.empty?
    subgroup = [todo.shift]
    notyet = []
    while !todo.empty?
      item = todo.shift
      (isCompatible(subgroup, item) ? subgroup : notyet) << item
    end
    puts "   Subgroup: #{subgroup.map { |item|
                          "id=#{item.id} title=#{item.title} date=#{item.published}\n" +
                          "               auths=#{item[:authors].to_a.join("; ")}\n" +
                          "               authKeys=#{item[:authorKeys].to_a.sort.join(",")} ids=#{item[:ids]}" }.
                          join("\n             ")}"
    # Do pairwise comparisons unless there are an unreasonable number
    if subgroup.length < 5
      compareFileCombos(subgroup)
    end
    todo = notyet
  end
end

###################################################################################################
def groupTitles
  query = Item.where(status: "published").order(Sequel.lit("attrs->>'$.title_key'")).
               select(:id, :published, :title, Sequel.as(Sequel.lit("attrs->>'$.title_key'"), :tk))
  if $fastMode
    query = query.where{Sequel.lit("attrs->>'$.title_key'") < 'b'}  # for testing, makes it quick (but very incomplete)
  end
  prevTk = nil
  titleGroup = []
  query.each { |item|
    tk = item[:tk]
    if prevTk && !shouldGroupTitleKeys(tk, prevTk)
      processTitleGroup(titleGroup)
      titleGroup.clear
    end
    titleGroup << { id: item.id, published: item.published, title: item.title, titleKey: tk }
    prevTk = tk
  }
  processTitleGroup(titleGroup)
end

###################################################################################################
# Main routine

groupTitles