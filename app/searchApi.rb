require 'sequel'
require 'json'
require 'pp'

###################################################################################################
# Model classes for easy interaction with the database.
#
# For more info on the database schema, see contents of migrations/ directory, and for a more
# graphical version, see:
#
# https://docs.google.com/drawings/d/1gCi8l7qteyy06nR5Ol2vCknh9Juo-0j91VGGyeWbXqI/edit

class Unit < Sequel::Model
  unrestrict_primary_key
  one_to_many :unit_hier,     :class=>:UnitHier, :key=>:unit_id
  one_to_many :ancestor_hier, :class=>:UnitHier, :key=>:ancestor_unit
end

class UnitHier < Sequel::Model(:unit_hier)
  unrestrict_primary_key
  many_to_one :unit,          :class=>:Unit
  many_to_one :ancestor,      :class=>:Unit, :key=>:ancestor_unit
end

class Item < Sequel::Model
  unrestrict_primary_key
end

class UnitItem < Sequel::Model
  unrestrict_primary_key
end

class Item < Sequel::Model
  unrestrict_primary_key
end

class ItemAuthors < Sequel::Model(:item_authors)
  unrestrict_primary_key
end

class Section < Sequel::Model
end

class Issue < Sequel::Model
end

AWS_URL = URI('http://localhost:8888/2013-01-01/search')

FACETS = ['type_of_work', 'peer_reviewed', 'supp_file_types', 'pub_year', 'campuses', 'departments', 'journals', 'disciplines', 'rights']

# TODO: figure out how get_query_display works for pub_year_start and pub_year_end
def get_query_display(params)
  filters = {}
  
  if params.key?('type_of_work')
    filters['type_of_work'] = {'display' => 'Type of Work', 'fieldName' => 'type_of_work', 'filters' => get_type_of_work_display_name(params['type_of_work'].map { |v| {'value' => v} })}
  end
  if params.key?('peer_reviewed')
    filters['peer_reviewed'] = {'display' => 'Peer Review', 'fieldName' => 'peer_reviewed', 'filters' => params['peer_reviewed'].map{ |v| {'value' => v} }}
  end
  if params.key?('supp_file_types')
    filters['supp_file_types'] = {'display' => 'Included Media', 'fieldName' => 'supp_file_types', 'filters' => capitalize_display_name(params['supp_file_types'].map{ |v| {'value' => v} })}
  end
  if params.key?('pub_year')
    filters['pub_year'] = {'display' => 'Publication Year', 'fieldName' => 'pub_year', 'input' => parse_range(params['pub_year'])}
  end
  if params.key?('campuses')
    filters['campuses'] = {'display' => 'Campus', 'fieldName' => 'campuses', 'filters' => get_unit_display_name(params['campuses'].map{ |v| {'value' => v} })}
  end
  if params.key?('deparments')
    filters['departments'] = {'display' => 'Department', 'fieldName' => 'departments', 'filters' => params['departments'].map{ |v| {'value' => v} }}
  end
  if params.key?('journals')
    filters['journals'] = {'display' => 'Journal', 'fieldName' => 'journals', 'filters' => get_unit_display_name(params['journals'].map{ |v| {'value' => v} })}
  end
  if params.key?('disciplines')
    filters['disciplines'] = {'display' => 'Discipline', 'fieldName' => 'disciplines', 'filters' => params['disciplines'].map{ |v| {'value' => v} }}
  end
  if params.key?('rights')
    filters['rights'] = {'display' => 'Reuse License', 'fieldName' => 'rights', 'filters' => params['rights'].map{ |v| {'value' => v} }}
  end
  
  display_params = {
    'q' => params['q'] ? params['q'].join(" ") : 'test',
    'filters' => filters
  }
end

def aws_encode(params)
  fq = []
  FACETS.each do |field_type|
    if params[field_type].length > 0
      if field_type != 'pub_year'
        filters = params[field_type].map { |filter| "#{field_type}: '#{filter}'" }
      else
        filters = params[field_type].map { |filter| "#{field_type}: #{filter}" }
      end
      filters = filters.join(" ")
      if params[field_type].length > 1 then filters = "(or #{filters})" end
      fq.push(filters)
    end
  end
  
  if (params['pub_year_start'].length > 0 || params['pub_year_end'].length > 0) && 
    (params['pub_year_start'][0] != "" || params['pub_year_end'][0] != "")
    
    if params['pub_year_start'].length > 0 && params['pub_year_start'][0] != ""
      date_range = "[#{params['pub_year_start'][0]},"
    else
      date_range = "{,"
    end
    
    if params['pub_year_end'].length > 0 && params['pub_year_end'][0] != ""
      date_range = "#{date_range}#{params['pub_year_end'][0]}]"
    else
      date_range = "#{date_range}}"
    end
    
    fq.push("pub_year: #{date_range}")
  end

  if fq.length > 1
    fq = fq.join(" ")
    fq = "(and #{fq})"
  elsif fq.length == 1
    fq = fq.join(" ")
  end

  # per message from Lisa 9/13/2016 regarding campus facets:
  #   - lbnl should be lbl (unsure if it should be LBL in the display too?)
  #   - ANR (Agriculture and Natural Resources) should be added to this list

  aws_params = {
    'q' => params['q'] ? params['q'].join(" ") : 'test',
    'size' => params['size'] ? params['size'] : 10,
    
    'facet.type_of_work' => "{buckets: ['article', 'monograph', 'dissertation', 'multimedia']}",
    'facet.peer_reviewed' => "{buckets: [1]}",
    'facet.supp_file_types' => "{buckets: ['video', 'audio', 'images', 'zip', 'other files']}",
    'facet.campuses' => "{buckets: ['ucb', 'ucd', 'uci', 'ucla', 'ucm', 'ucr', 'ucsd', 'ucsf', 'ucsb', 'ucsc', 'ucop', 'lbnl']}",
    'facet.departments' => "{sort: 'count', size: 100}",
    'facet.journals' => "{sort: 'count', size: 100}",
    'facet.disciplines' => "{sort: 'count', size: 100}",
    'facet.rights' => "{sort: 'count', size: 100}"
  }
  
  if fq.length > 0 then aws_params['fq'] = fq end
  
  aws_params = URI::encode_www_form(aws_params)
end

def facet_secondary_query(params, field_type)
  params.delete(field_type)
  url = AWS_URL.clone
  url.query = aws_encode(params)
  response = JSON.parse(Net::HTTP.get(url))
  return response['facets'][field_type]
end

def get_unit_display_name(unitFacets)
  for unitFacet in unitFacets
    unit = Unit[unitFacet['value']]
    unitFacet['displayName'] = unit.name
  end
end

def get_type_of_work_display_name(facetList)
  for facet in facetList    
    if facet['value'] == 'article' then facet['displayName'] = 'Article' end
    if facet['value'] == 'monograph' then facet['displayName'] = 'Book' end
    if facet['value'] == 'dissertation' then facet['displayName'] = 'Theses' end
    if facet['value'] == 'multimedia' then facet['displayName'] = 'Multimedia' end
  end
end

def get_unit_hierarchy(unitFacets)
  for unitFacet in unitFacets
    unit = Unit[unitFacet['value']]
    unitFacet['displayName'] = unit.name

    # get the direct ancestor to this oru unit if the ancestor is also an oru
    ancestors = UnitHier.where(unit_id: unit.id).where(is_direct: true).where(ancestor: Unit.where(type: 'oru')).all

    if ancestors.length == 1
      # search the rest of the list to see if this ancestor is already in the facet list
      ancestor_id = ancestors[0].ancestor_unit
      ancestor_in_list = false
      for u in unitFacets
        if ancestor_id == u['value']
          if u.key? 'descendents'
            u['descendents'].push(unitFacet)
          else
            u['descendents'] = [unitFacet]
          end
          ancestor_in_list = true
          unitFacet['ancestor_in_list'] = true
        end
      end

      if !ancestor_in_list
        ancestor = Unit[ancestors[0].ancestor_unit]
        unitFacet['ancestor'] = {displayName: ancestor.name, value: ancestor.id}
      end
    elsif ancestors.length > 1
      pp "DON'T KNOW WHAT TO DO HERE YIKES"
    end
  end

  for unitFacet in unitFacets
    if unitFacet['ancestor_in_list']
      unitFacets.delete(unitFacet)
    end
  end
end

def capitalize_display_name(facetList)
  for facet in facetList
    facet['displayName'] = facet['value'].capitalize
  end
end

def parse_range(range)
  pp range
end

def search(params)
  url = AWS_URL.clone
  url.query = aws_encode(params)
  response = JSON.parse(Net::HTTP.get(url))
  
  searchResults = []
  if response['hits'] && response['hits']['hit']
    for indexItem in response['hits']['hit']
      item = Item[indexItem['id']]
      if item
        itemHash = {
          :id => item.id,
          :title => item.title,
          :genre => item.genre,
          :rights => item.rights,
          :content_type => item.content_type,
          :pub_date => item.pub_date
        }
      
        itemAttrs = JSON.parse(item.attrs)
        itemHash[:peerReviewed] = itemAttrs['is_peer_reviewed']
        itemHash[:abstract] = itemAttrs['abstract']
      
        itemAuthors = ItemAuthors.where(item_id: indexItem['id']).order(:ordering).all
        itemHash[:authors] = itemAuthors.map { |author| JSON.parse(author.attrs) }
      
        #if journal, section will be non-nil, follow section link to issue (get volume), follow to unit table
        #item link to the unit should be the same as section link to the unit      
        if item.section
          itemIssue = Issue[Section[item.section].issue_id]
          itemUnit = Unit[itemIssue.unit_id]
          itemHash[:journalInfo] = {displayName: "#{itemUnit.name}, #{itemIssue.volume}, #{itemIssue.issue}", issueId: itemIssue.id}
        #otherwise, use the item link to the unit table for all other content types
        else
          unitItem = UnitItem[:item_id => indexItem['id']]
          if unitItem
            unit = Unit[:id => unitItem.unit_id]
            itemHash[:unitInfo] = {displayName: unit.name, unitId: unit.id}
          end
        end
      
        searchResults << itemHash
      else
        puts 'NilClass: '
        puts indexItem['id']
      end
    end
  end
  
  facetHash = response['facets']
  FACETS.each do |field_type|
    if field_type != 'pub_year' && params.key?(field_type) 
      facetHash[field_type] = facet_secondary_query(params.clone, field_type)
    end
  end

  # put facets into an array to maintain a specific order, apply facet-specific augmentation like including display values (see journal)
  facets = [
    {'display' => 'Type of Work', 'fieldName' => 'type_of_work', 'facets' => get_type_of_work_display_name(facetHash['type_of_work']['buckets'])},
    {'display' => 'Peer Review', 'fieldName' => 'peer_reviewed', 
      'facets' => [{'value' => "1", 'count' => facetHash['peer_reviewed']['buckets'][0]['count'], 'displayName' => 'Peer-reviewed only'}] },
    {'display' => 'Included Media', 'fieldName' => 'supp_file_types', 'facets' => capitalize_display_name(facetHash['supp_file_types']['buckets'])},
    {'display' => 'Publication Year', 'fieldName' => 'pub_year', 'range' => {pub_year_start: params['pub_year_start'][0], pub_year_end: params['pub_year_end'][0]}},
    {'display' => 'Campus', 'fieldName' => 'campuses', 'facets' => get_unit_display_name(facetHash['campuses']['buckets'])},
    {'display' => 'Departments', 'fieldName' => 'departments', 'facets' => get_unit_hierarchy(facetHash['departments']['buckets'])},
    {'display' => 'Journal', 'fieldName' => 'journals', 'facets' => get_unit_display_name(facetHash['journals']['buckets'])},
    {'display' => 'Discipline', 'fieldName' => 'disciplines', 'facets' => facetHash['disciplines']['buckets']},
    {'display' => 'Reuse License', 'fieldName' => 'rights', 'facets' => facetHash['rights']['buckets']}
  ]

  return {'count' => response['hits']['found'], 'query' => get_query_display(params.clone), 'searchResults' => searchResults, 'facets' => facets}
end