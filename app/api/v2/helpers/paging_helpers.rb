module PagingHelpers

  A_ENTRIES_PER_PAGE = 30

  def make_paging_object(query_results)
		SearchResults.new({
      current_page: query_results.current_page,
      per_page: query_results.per_page,
      total_entries: query_results.total_entries,
      total_pages: query_results.total_pages
    })
  end

  def make_paging_for_references( page, total_count )
    if total_count.to_i > A_ENTRIES_PER_PAGE
      total_pages =  total_count / A_ENTRIES_PER_PAGE
      total_pages += 1 if ((total_count % A_ENTRIES_PER_PAGE) > 0)
    else
      total_pages = 1
    end
    SearchResults.new({
      current_page: page,
      per_page: A_ENTRIES_PER_PAGE,
      total_entries: total_count,
      total_pages: total_pages
    })
  end

end
