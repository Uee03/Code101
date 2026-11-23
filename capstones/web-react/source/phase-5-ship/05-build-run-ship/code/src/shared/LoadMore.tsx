export function LoadMore({ query }: { query: { hasNextPage: boolean; isFetchingNextPage: boolean; fetchNextPage: () => Promise<unknown> } }) {
  return <button disabled={!query.hasNextPage || query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>
    {query.isFetchingNextPage ? 'Loading' : query.hasNextPage ? 'Load more' : 'End of list'}
  </button>;
}
