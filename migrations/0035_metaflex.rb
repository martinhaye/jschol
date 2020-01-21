require 'json'

Sequel.migration do
  up do
    create_table(:formats) do
      String :id, primary_key: true, null: false
      String :descrip, null: false
    end

    from(:formats).insert(id: 'text',         descrip: "Plain string or number, no HTML")
    from(:formats).insert(id: 'choice',       descrip: "Constrained string (or number) from a list of choices")
    from(:formats).insert(id: 'html',         descrip: "HTML-formatted text")
    from(:formats).insert(id: 'date',         descrip: "A date (YYYY-MM-DD)")
    from(:formats).insert(id: 'boolean',      descrip: "True/Yes or False/No")
    from(:formats).insert(id: 'person_list',  descrip: "One or more people (or organizations)")
    from(:formats).insert(id: 'text_list',    descrip: "One or more plain text items, e.g. keywords")
    from(:formats).insert(id: 'choice_list',  descrip: "One or more strings from a list of choices")
    from(:formats).insert(id: 'isbn',         descrip: "International Standard Book Number (ISBN-10 or ISBN-13)")
    from(:formats).insert(id: 'issn',         descrip: "International Standard Serial Number")
    from(:formats).insert(id: 'url',          descrip: "Uniform Resource Locator (on the web)")
    from(:formats).insert(id: 'doi',          descrip: "Digital Object Identifier")
    from(:formats).insert(id: 'pagination',   descrip: "First and last page")
    from(:formats).insert(id: 'data_avail',   descrip: "Data availability statement")
    from(:formats).insert(id: 'embargo_date', descrip: "Date to release embargo, in the near future")
    from(:formats).insert(id: 'rights',       descrip: "Either 'public' or a Creative Commons license")
    from(:formats).insert(id: 'image',        descrip: "An image (e.g. cover image)")
    from(:formats).insert(id: 'id_list',      descrip: "List of typed identifiers (e.g. local_ids)")

    create_table(:fields) do
      String :id, primary_key: true, null: false
      foreign_key :format_id, :formats, type: String, null: false
      String :attrs, :type=>'JSON'
        # name (displayed on input forms)
        # placeholder (displayed on input forms inside the box)
        # descrip: html (displayed on input forms)
        # display_name (optional; displayed to end-users)
        # person_role (required if format="person_list")
        # choices (if format = "choice" or "choice_list")
        # ++ "id: display text" e.g. for ext_pub_status
        # ++ "text" e.g. for discipline
        # ++ ? maybe including "grouped" e.g. "Group A | option 1", "Group A | option 2", "Group B | option 3"
        # input_type: dropdown/radio/(?grouped) for choices; textbox/textarea for text
        # input_size: # chars for textbox, # lines for textarea
        # is_always_required: boolean
    end

    from(:fields).insert(id: 'title', format_id: 'html',
      attrs: { name: "Title", descrip: "Official title of the publication", is_always_required: true }.to_json )
    from(:fields).insert(id: 'published', format_id: 'date',
      attrs: { name: "Publication Date", descrip: "Date this was published", is_always_required: true }.to_json )

    create_table(:pubtypes) do
      String :id, primary_key: true, null: false
      foreign_key :cloned_from, :pubtypes, type: String
      String :attrs, :type=>'JSON'
        # is_default - shows up by default for all units
        # singular_name
        # plural_name
        # descrip: html
    end

    create_table(:pubtype_fields) do
      primary_key :id
      foreign_key :pubtype_id, :pubtypes, type: String, null: false
      foreign_key :field_id, :fields, type: String, null: false
      Integer :ordering, :null=>false
      String :attrs, :type=>'JSON'
        # is_required: boolean
        # is_essential: boolean
        # locked: boolean  (for data from a data source that we don't want users mucking with)
      index [:pubtype_id, :ordering], unique: true
      index [:pubtype_id, :field_id], unique: true
    end
  end

  down do
    drop_table(:pubtype_fields)
    drop_table(:pubtypes)
    drop_table(:fields)
    drop_table(:formats)
  end
end
