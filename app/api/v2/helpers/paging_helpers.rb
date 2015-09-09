module PagingHelpers

  def make_paging_object(query_results)
		SearchResults.new({
      current_page: query_results.current_page,
      per_page: query_results.per_page,
      total_entries: query_results.total_entries,
      total_pages: query_results.total_pages
    })
  end

  def make_paging_for_references( page, total_count )
    total_pages = total_count / 30
    total_pages += total_count % 30
    SearchResults.new({
      current_page: page,
      per_page: 30,
      total_entries: total_count,
      total_pages: total_pages
    })
  end

end
