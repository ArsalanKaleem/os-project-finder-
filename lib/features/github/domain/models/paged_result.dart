/// Simple container for one page of a paginated search.
class PagedResult<T> {
  const PagedResult({required this.items, required this.totalCount});

  final List<T> items;
  final int totalCount;

  bool hasMore(int loadedSoFar) => loadedSoFar < totalCount;
}
